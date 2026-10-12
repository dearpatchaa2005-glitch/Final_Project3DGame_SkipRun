extends SceneTree
func _init():
	var q := (load("res://characters/character@Jump.fbx") as PackedScene).instantiate()
	var ap: AnimationPlayer = q.get_child(1)
	var a := ap.get_animation("mixamo_com")
	for t in a.get_track_count():
		if str(a.track_get_path(t)).ends_with("Hips") and a.track_get_type(t) == Animation.TYPE_POSITION_3D:
			for k in range(0, a.track_get_key_count(t), 3):
				var v: Vector3 = a.track_get_key_value(t, k)
				print("t=%.2f y=%.3f z=%.3f" % [a.track_get_key_time(t, k), v.y, v.z])
	quit()
