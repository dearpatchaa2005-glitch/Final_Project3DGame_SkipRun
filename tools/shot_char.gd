extends SceneTree
# ใช้ตรวจหน้าตาตัวละครแบบ render จริง:  godot --path . --script res://tools/shot_char.gd
var out_dir := "/tmp/claude-0/-home-claude/eb5cd129-ae76-52da-b984-f0e3ad224657/scratchpad/shots"
func _initialize():
	DirAccess.make_dir_recursive_absolute(out_dir)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.74, 0.88, 0.97)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 0.9)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); root.add_child(sun)
	var cam := Camera3D.new(); root.add_child(cam)
	var miw := CharacterModel.new(); miw.outfit = "miw"; miw.position = Vector3(-0.8, 0, 0); root.add_child(miw)
	var win := CharacterModel.new(); win.outfit = "winai"; win.position = Vector3(0.8, 0, 0); root.add_child(win)
	await process_frame
	await process_frame
	var shots := [
		["idle_front", "Idle", 0.5, Vector3(0, 1.0, 3.4), Vector3(0, 0.9, 0)],
		["idle_back", "Idle", 0.5, Vector3(0, 1.2, -3.4), Vector3(0, 0.9, 0)],
		["run_back", "Run", 0.2, Vector3(0, 2.0, -3.6), Vector3(0, 0.9, 0)],
		["run_side", "Run", 0.35, Vector3(3.6, 1.1, 0), Vector3(0, 0.9, 0)],
		["jump_back", "Jump", 0.95, Vector3(0, 1.8, -3.6), Vector3(0, 1.0, 0)],
		["jump_side", "Jump", 1.25, Vector3(3.6, 1.1, 0), Vector3(0, 1.0, 0)],
		["head_close", "Idle", 0.5, Vector3(0, 1.75, 1.5), Vector3(0, 1.6, 0)],
	]
	for s in shots:
		for m in [miw, win]:
			m.anim.play(s[1]); m.anim.seek(s[2], true); m.anim.pause()
		cam.position = s[3]
		cam.look_at(s[4])
		for i in 3: await process_frame
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("%s/%s.png" % [out_dir, s[0]])
		print("saved ", s[0], " ", img.get_size())
	quit()
