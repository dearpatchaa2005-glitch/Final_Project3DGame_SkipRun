extends SceneTree
func _init():
	for f in ["Idle","Running","Walking","Jump"]:
		var q := (load("res://characters/character@%s.fbx" % f) as PackedScene).instantiate()
		var ap: AnimationPlayer = null
		for d in q.get_children():
			if d is AnimationPlayer: ap = d
		var a := ap.get_animation("mixamo_com")
		print("== ", f, " len ", a.length, " tracks ", a.get_track_count(), " root_node ", ap.root_node)
		for t in a.get_track_count():
			var path := str(a.track_get_path(t))
			if path.ends_with("Hips") and a.track_get_type(t) == Animation.TYPE_POSITION_3D:
				var mn := Vector3(INF,INF,INF); var mx := -mn
				for k in a.track_get_key_count(t):
					var v: Vector3 = a.track_get_key_value(t, k)
					mn = mn.min(v); mx = mx.max(v)
				print("  hips pos ", path, " min ", mn, " max ", mx, " keys ", a.track_get_key_count(t))
		q.free()
	var q2 := (load("res://characters/character@Idle.fbx") as PackedScene).instantiate()
	var sk: Skeleton3D = q2.get_child(0)
	for bn in ["mixamorig_LeftUpLeg","mixamorig_LeftLeg","mixamorig_LeftArm","mixamorig_Spine2","mixamorig_Head"]:
		var i := sk.find_bone(bn)
		print(bn, " rest basis ", sk.get_bone_global_rest(i).basis.get_euler() * 57.2958)
	quit()
