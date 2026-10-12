extends Node
## สร้างไฟล์ฉาก .tscn ของเกม (player.tscn, teacher.tscn, main.tscn) ด้วยโค้ด
## รันครั้งเดียวเพื่อสร้างไฟล์:   godot --headless --path . res://tools/build_scenes.tscn
## หลังจากนั้นเปิดแก้ใน Godot Editor ได้ตามปกติ (ไม่ต้องรันสคริปต์นี้อีก)


func _ready() -> void:
	_build_player()
	_build_teacher()
	_build_main()
	print("สร้างฉากเสร็จแล้ว: scenes/player.tscn, scenes/teacher.tscn, scenes/main.tscn")
	get_tree().quit()


func _own(root: Node, n: Node) -> void:
	for c in n.get_children():
		c.owner = root
		if c.scene_file_path.is_empty():
			_own(root, c)


func _save(root: Node, path: String) -> void:
	_own(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack ไม่สำเร็จ: " + path)
	err = ResourceSaver.save(ps, path)
	if err != OK:
		push_error("save ไม่สำเร็จ: " + path)
	root.free()


# --------------------------------------------------------------- player
func _build_player() -> void:
	var root := CharacterBody3D.new()
	root.name = "Player"
	root.set_script(load("res://scripts/player.gd"))

	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.7
	cs.shape = cap
	cs.position = Vector3(0, 0.85, 0)
	root.add_child(cs)

	var model := Node3D.new()
	model.name = "Model"
	model.set_script(load("res://scripts/character_model.gd"))
	model.set("outfit", "miw")
	root.add_child(model)

	var foot := AudioStreamPlayer.new()
	foot.name = "Footsteps"
	foot.stream = load("res://sounds/walking.ogg")
	foot.volume_db = -14.0
	foot.autoplay = true
	root.add_child(foot)

	var dust := CPUParticles3D.new()
	dust.name = "Dust"
	dust.position = Vector3(0, 0.1, 0.35)
	dust.emitting = false
	dust.amount = 16
	dust.lifetime = 0.5
	dust.direction = Vector3(0, 0.4, 1)
	dust.spread = 30.0
	dust.initial_velocity_min = 1.5
	dust.initial_velocity_max = 3.0
	dust.gravity = Vector3(0, 0.6, 0)
	dust.scale_amount_min = 0.4
	dust.scale_amount_max = 0.9
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0.65), Color(1, 1, 1, 0.0)])
	dust.color_ramp = ramp
	var quad := QuadMesh.new()
	quad.size = Vector2(0.5, 0.5)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.vertex_color_use_as_albedo = true
	var soft := GradientTexture2D.new()
	var soft_g := Gradient.new()
	soft_g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	soft.gradient = soft_g
	soft.fill = GradientTexture2D.FILL_RADIAL
	soft.fill_from = Vector2(0.5, 0.5)
	soft.fill_to = Vector2(1.0, 0.5)
	soft.width = 64
	soft.height = 64
	qm.albedo_texture = soft
	quad.material = qm
	dust.mesh = quad
	root.add_child(dust)

	_save(root, "res://scenes/player.tscn")


# -------------------------------------------------------------- teacher
func _build_teacher() -> void:
	var root := Node3D.new()
	root.name = "Teacher"
	root.set_script(load("res://scripts/teacher.gd"))
	var model := Node3D.new()
	model.name = "Model"
	model.set_script(load("res://scripts/character_model.gd"))
	model.set("outfit", "winai")
	model.set("target_height", 1.82)
	root.add_child(model)
	_save(root, "res://scenes/teacher.tscn")


# ----------------------------------------------------------------- main
func _build_main() -> void:
	var root := Node3D.new()
	root.name = "Main"
	root.set_script(load("res://scripts/main.gd"))

	# สภาพแวดล้อม: ท้องฟ้ายามเช้า + หมอกบาง ๆ ซ่อนจุดที่ของโผล่
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.26, 0.58, 1.0)
	sky_mat.sky_horizon_color = Color(1.0, 0.78, 0.62)
	sky_mat.ground_horizon_color = Color(1.0, 0.78, 0.62)
	sky_mat.ground_bottom_color = Color(0.72, 0.74, 0.78)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.78
	env.fog_enabled = true
	env.fog_light_color = Color(1.0, 0.84, 0.70)
	env.fog_density = 0.0105
	env.fog_sky_affect = 0.2
	env.adjustment_enabled = true             # สีสดจัดจ้านแบบเมืองยามเช้า
	env.adjustment_saturation = 1.2
	env.adjustment_contrast = 1.05
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.light_color = Color(1.0, 0.91, 0.76)
	sun.light_energy = 0.56
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 55.0
	sun.shadow_bias = 0.06
	root.add_child(sun)

	var track := Node3D.new()
	track.name = "Track"
	track.set_script(load("res://scripts/track.gd"))
	root.add_child(track)

	var school := Node3D.new()
	school.name = "School"
	school.set_script(load("res://scripts/school.gd"))
	root.add_child(school)

	var ground := StaticBody3D.new()
	ground.name = "Ground"
	ground.collision_layer = 8
	ground.collision_mask = 0
	var gs := CollisionShape3D.new()
	gs.name = "CollisionShape3D"
	var gb := BoxShape3D.new()
	gb.size = Vector3(30, 2, 80)
	gs.shape = gb
	gs.position = Vector3(0, -1, 0)
	ground.add_child(gs)
	root.add_child(ground)

	var spawned := Node3D.new()
	spawned.name = "Spawned"
	root.add_child(spawned)

	root.add_child(_build_preview())

	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	player.name = "Player"
	root.add_child(player)

	var teacher := (load("res://scenes/teacher.tscn") as PackedScene).instantiate()
	teacher.name = "Teacher"
	teacher.position = Vector3(0, 0, 5.0)
	root.add_child(teacher)

	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.fov = 60.0
	cam.near = 0.1
	cam.far = 260.0
	cam.current = true
	cam.transform = Transform3D(Basis(), Vector3(0, 5.4, 11.0)).looking_at(Vector3(0, 0.7, -4.0), Vector3.UP)
	root.add_child(cam)

	var ui := CanvasLayer.new()
	ui.name = "UI"
	ui.set_script(load("res://scripts/game_ui.gd"))
	root.add_child(ui)

	_save(root, "res://scenes/main.tscn")


# ------------------------------------------------- ฉากตัวอย่างใน Editor
## วางถนน ตึก รถ คนเดิน สิ่งกีดขวาง ดาว ไอเท็ม เป็นโหนดจริงในฉาก main.tscn
## (ตอนเล่นเกม โหนด EditorPreview จะลบตัวเอง — ดู scripts/editor_preview.gd)
func _build_preview() -> Node3D:
	var pv := Node3D.new()
	pv.name = "EditorPreview"
	pv.set_script(load("res://scripts/editor_preview.gd"))

	# ---- ถนนและตึกสองฝั่ง (ตรงช่วงแรก แล้วโค้ง) ----
	var road := RoadPath.new()
	road.straight_start = 70.0
	road.reset(7)
	RoadPath.active = road
	var street := Node3D.new()
	street.name = "Street"
	pv.add_child(street)
	var tr := Track.new()
	tr.path = road
	tr.ahead = 170.0
	tr.behind = 30.0
	tr.reset(7)
	tr.update_for(0.0)
	for c in tr.get_children():
		tr.remove_child(c)
		street.add_child(c)
	tr.free()

	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var lanes: Array[float] = [-2.2, 0.0, 2.2]

	# ---- สิ่งกีดขวาง (หน้าตาเดียวกับที่เกมสร้างตอนเล่น) ----
	var obs := Node3D.new()
	obs.name = "Obstacles"
	pv.add_child(obs)
	var groups := {}
	for g in ["Low_กระโดดข้าม", "High_ก้มมุด", "Traffic_สลับเลนหลบ"]:
		var n := Node3D.new()
		n.name = g
		obs.add_child(n)
		groups[g.split("_")[0]] = n
	# [ชนิด, เลน, ระยะ s (ม.), กลุ่ม, ชื่อโหนด]
	var layout := [
		["cone", 0, 14.0, "Low", "Cone"], ["crates", 2, 14.0, "Low", "Crates"],
		["car", 1, 24.0, "Traffic", "Car"],
		["gate", -1, 32.0, "High", "CrossingGate"],
		["bench", 0, 40.0, "Low", "Bench"], ["walker", 2, 40.0, "Traffic", "Pedestrian"],
		["bus", 1, 50.0, "Traffic", "Bus"],
		["sign", 0, 60.0, "High", "ShopSign"], ["barrier", 2, 60.0, "Low", "Barrier"],
		["trash", 1, 72.0, "Low", "TrashBags"], ["car", 0, 72.0, "Traffic", "Car"],
		["sign", -1, 86.0, "High", "ShopSign"],
		["car", 2, 100.0, "Traffic", "Car"], ["cone", 1, 112.0, "Low", "Cone"],
		["bus", 0, 124.0, "Traffic", "Bus"], ["walker", 1, 136.0, "Traffic", "Pedestrian"],
		["gate", -1, 148.0, "High", "CrossingGate"], ["crates", 0, 158.0, "Low", "Crates"],
	]
	for e in layout:
		var o := Obstacle.create(e[0], e[1], rng)
		var v := o.visual
		if v == null:
			o.free()
			continue
		o.s = e[2]
		o.place()
		o.remove_child(v)
		v.transform = o.transform * v.transform
		v.name = e[4]
		groups[e[3]].add_child(v)
		o.free()

	# ---- เหรียญดาว ----
	var stars := Node3D.new()
	stars.name = "Stars"
	pv.add_child(stars)
	for trail in [[2, 18.0], [0, 30.0], [2, 45.0], [1, 62.0], [0, 90.0], [2, 118.0], [1, 140.0]]:
		for k in 5:
			var m := MeshInstance3D.new()
			m.name = "Star"
			m.mesh = Props.star_mesh()
			m.material_override = Props.glow_mat(Color(1.0, 0.80, 0.12), 0.7)
			var ss: float = trail[1] + k * 1.7
			m.position = road.pos(ss, lanes[trail[0]]) + Vector3(0, 1.05, 0)
			m.rotation.y = road.yaw(ss)
			stars.add_child(m)

	# ---- ไอเท็มพิเศษ ----
	var items := Node3D.new()
	items.name = "PowerUps"
	pv.add_child(items)
	var item_list := [["shield", 0, 34.0], ["magnet", 2, 54.0], ["boost", 0, 76.0], ["shield", 2, 104.0], ["boost", 1, 128.0]]
	for it in item_list:
		var pu := PowerUp.create(it[0], road.pos(it[2], lanes[it[1]]) + Vector3(0, 1.1, 0), it[2])
		pu.set_script(null)
		pu.name = "Item_" + it[0]
		pu.rotation.y = road.yaw(it[2])
		items.add_child(pu)

	_name_parts(pv)
	return pv


## ตั้งชื่อชิ้นส่วนที่ไม่มีชื่อให้อ่านง่ายใน Scene tree
func _name_parts(n: Node) -> void:
	for c in n.get_children():
		if c.scene_file_path.is_empty():
			if String(c.name).begins_with("@"):
				if c is MeshInstance3D:
					var mesh := (c as MeshInstance3D).mesh
					c.name = "Part" if mesh == null else mesh.get_class().replace("Mesh", "")
				else:
					c.name = c.get_class()
			_name_parts(c)
