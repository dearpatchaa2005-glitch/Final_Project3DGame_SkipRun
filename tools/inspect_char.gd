extends SceneTree
func _init():
	var p: PackedScene = load("res://characters/character@Idle.fbx")
	var n := p.instantiate()
	root.add_child(n)
	print("ROOT ", n.name, " scale ", n.scale, " children: ", n.get_children().map(func(c): return c.name + ":" + c.get_class()))
	var stack := [n]
	while stack:
		var x: Node = stack.pop_back()
		if x is Skeleton3D:
			var s := x as Skeleton3D
			print("SKEL ", s.get_path(), " bones=", s.get_bone_count(), " xform=", s.transform)
			for i in s.get_bone_count():
				print("  bone ", i, " ", s.get_bone_name(i), " parent ", s.get_bone_parent(i), " rest_origin ", s.get_bone_global_rest(i).origin)
		if x is MeshInstance3D:
			var m := x as MeshInstance3D
			print("MESH ", x.name, " surfaces=", m.mesh.get_surface_count(), " aabb=", m.get_aabb())
			for i in m.mesh.get_surface_count():
				print("   mat ", i, m.mesh.surface_get_material(i))
		for c in x.get_children(): stack.append(c)
	for f in ["Idle","Running","Walking","Jump"]:
		var q := (load("res://characters/character@%s.fbx" % f) as PackedScene).instantiate()
		var ap: AnimationPlayer = null
		for d in q.get_children():
			if d is AnimationPlayer: ap = d
		print(f, " anims=", ap.get_animation_list() if ap else "none", " len=", Array(ap.get_animation_list()).map(func(a): return ap.get_animation(a).length) if ap else "")
		q.free()
	quit()
