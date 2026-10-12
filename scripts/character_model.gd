@tool
class_name CharacterModel
extends Node3D
## =====================================================================
##  ตัวละคร 3D ของเกม Skip Run
##
##  ใช้หุ่น Mixamo + ท่าทางจาก GameLab6 (Idle / Running / Walking / Jump)
##  แล้ว "แต่งตัว" ด้วยโค้ด (ทำนองเดียวกับชุดซานต้าใน Lab 6)
##    outfit = "miw"   -> มิว: ชุดนักเรียนชาย (เสื้อขาว กางเกงขาสั้นกรมท่า ถุงเท้าขาว) กระเป๋าสะพายหลัง ผมดำสั้น
##    outfit = "winai" -> ครูวินัย: เสื้อข้าราชการสีกากี กางเกงสแลค สายคล้องบัตร แว่น หนวด ไม้เรียว
##
##  ชิ้นส่วนเสื้อผ้าผูกกับกระดูกจริง จึงขยับตามท่าทางทุกเฟรม
##  (ไม่ต้องรู้ทิศแกนของกระดูก เพราะคำนวณจากตำแหน่งข้อต่อโดยตรง)
## =====================================================================

@export_enum("miw", "winai") var outfit: String = "miw"
## ความสูงตัวละครในโลกเกม (เมตร)
@export var target_height: float = 1.75

const ANIM_FILES := {
	"Idle": "res://characters/character@Idle.fbx",
	"Run": "res://characters/character@Running.fbx",
	"Walk": "res://characters/character@Walking.fbx",
	"Jump": "res://characters/character@Jump.fbx",
}

# ---- สี ----
const SKIN_MIW := Color(0.96, 0.76, 0.62)
const SKIN_WINAI := Color(0.86, 0.66, 0.52)
const HAIR_MIW := Color(0.07, 0.05, 0.05)
const HAIR_WINAI := Color(0.10, 0.09, 0.09)
const SHIRT_RED := Color(0.95, 0.24, 0.22)
const JEANS := Color(0.10, 0.18, 0.45)
const BLACK := Color(0.08, 0.08, 0.10)
const WHITE := Color(0.97, 0.97, 0.97)
const SHIRT_BLUE := Color(0.50, 0.66, 0.88)
const VEST_NAVY := Color(0.13, 0.17, 0.33)
const TROUSERS := Color(0.17, 0.25, 0.42)
const TIE_DARK := Color(0.10, 0.12, 0.20)
const UNI_WHITE := Color(0.97, 0.97, 0.98)
const SKIRT_NAVY := Color(0.10, 0.14, 0.34)
const KHAKI := Color(0.80, 0.70, 0.47)
const SLACKS := Color(0.13, 0.13, 0.16)
const WOOD := Color(0.78, 0.55, 0.22)

var anim: AnimationPlayer
var skeleton: Skeleton3D
var rig: Node3D

var _scale_k := 1.0
var _segments: Array[Dictionary] = []
var _attachments: Array[Dictionary] = []
var _cur := ""


func _ready() -> void:
	build()


# ------------------------------------------------------------------ build
func build() -> void:
	var packed := load(ANIM_FILES["Idle"]) as PackedScene
	if packed == null:
		push_error("โหลด character@Idle.fbx ไม่ได้ — ตรวจโฟลเดอร์ characters/")
		return
	rig = packed.instantiate()
	rig.name = "Rig"
	add_child(rig)
	anim = _find_anim_player(rig)
	skeleton = _find_skeleton(rig)
	if anim == null or skeleton == null:
		push_error("ไม่พบ AnimationPlayer/Skeleton3D ในโมเดลตัวละคร")
		return

	_load_animations()
	_normalize()
	_paint_body()
	if outfit == "winai":
		_dress_winai()
	else:
		_dress_miw()
	skeleton.skeleton_updated.connect(_update_attachments)
	play("Idle")
	_update_attachments()


func _load_animations() -> void:
	var lib := AnimationLibrary.new()
	for key in ANIM_FILES.keys():
		var a := _extract_animation(ANIM_FILES[key])
		if a == null:
			push_warning("ข้ามท่า " + key)
			continue
		a.loop_mode = Animation.LOOP_NONE if key == "Jump" else Animation.LOOP_LINEAR
		_strip_root_motion(a, key)
		lib.add_animation(key, a)
	for lib_name in anim.get_animation_library_list():
		anim.remove_animation_library(lib_name)
	anim.add_animation_library("", lib)


func _extract_animation(path: String) -> Animation:
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var inst := packed.instantiate()
	var ap := _find_anim_player(inst)
	var out: Animation = null
	if ap != null:
		for n in ap.get_animation_list():
			if String(n) != "RESET":
				out = ap.get_animation(n).duplicate(true)
				break
	inst.free()
	return out


## ท่า Running/Walking ของ Mixamo มีการเคลื่อนที่ไปข้างหน้าที่สะโพก (root motion)
## ซึ่งจะทำให้ตัวละครสะดุดกลับทุกรอบ — ตัดแกน Z ออกให้วิ่งอยู่กับที่ (เกมเป็นคนเลื่อนตำแหน่งเอง)
## ท่า Jump ลดการยกสะโพกลง เพราะ CharacterBody เป็นคนกระโดดอยู่แล้ว
func _strip_root_motion(a: Animation, key: String) -> void:
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		if not str(a.track_get_path(t)).ends_with("Hips"):
			continue
		var rest_y := 1.009
		var first: Vector3 = a.track_get_key_value(t, 0)
		for k in a.track_get_key_count(t):
			var v: Vector3 = a.track_get_key_value(t, k)
			v.z = first.z
			if key == "Jump":
				v.y = rest_y + (v.y - rest_y) * 0.3
				v.x = first.x
			a.track_set_key_value(t, k, v)


func _normalize() -> void:
	# กระดูกบนสุด (HeadTop) ~ความสูงจริงของหุ่น
	var top := _bone_pos("HeadTop_End").y
	var h := maxf(top, 0.5)
	_scale_k = target_height / h
	rig.scale = Vector3.ONE * _scale_k


## ระบายสีเสื้อผ้าบนตัวหุ่นโดยตรง: ให้แต่ละจุดยอด (vertex) ได้สีตามกระดูกที่มีน้ำหนักมากที่สุด
## เช่น กระดูกลำตัว = สีเสื้อ, กระดูกขา = กางเกง, กระดูกเท้า = รองเท้า
## วิธีนี้ทำให้ได้ขอบเสื้อผ้าเรียบ ไม่มีผิวทะลุออกมา และขยับตามท่าทางอัตโนมัติ
func _paint_body() -> void:
	var palette := _palette()
	var body_mat := StandardMaterial3D.new()
	body_mat.vertex_color_use_as_albedo = true
	body_mat.vertex_color_is_srgb = true
	body_mat.albedo_color = Color.WHITE
	body_mat.roughness = 0.75
	for n in _walk(rig):
		if not (n is MeshInstance3D):
			continue
		var mi := n as MeshInstance3D
		var src := mi.mesh as ArrayMesh
		if src == null or mi.skin == null:
			continue
		var arrays := src.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		if verts.is_empty() or bones.is_empty():
			continue
		var per := bones.size() / verts.size()      # 4 หรือ 8 กระดูกต่อจุดยอด
		var bind_group: Array[String] = []
		for i in mi.skin.get_bind_count():
			var bname := mi.skin.get_bind_name(i)
			if bname.is_empty():
				bname = skeleton.get_bone_name(mi.skin.get_bind_bone(i))
			bind_group.append(_group_of(bname))
		var cols := PackedColorArray()
		cols.resize(verts.size())
		for v in verts.size():
			var best := 0
			var best_w := -1.0
			for k in per:
				var w := weights[v * per + k]
				if w > best_w:
					best_w = w
					best = bones[v * per + k]
			var grp := bind_group[best] if best < bind_group.size() else "spine"
			cols[v] = palette.get(grp, palette["skin"])
		arrays[Mesh.ARRAY_COLOR] = cols
		var flags := 0
		if per == 8:
			flags |= Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		var dst := ArrayMesh.new()
		dst.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
		mi.mesh = dst
		mi.set_surface_override_material(0, body_mat)


## จัดกลุ่มกระดูก Mixamo เป็นส่วนของร่างกาย
func _group_of(bone_name: String) -> String:
	var b := bone_name.to_lower()
	if b.contains("forearm"):
		return "forearm"
	if b.contains("hand"):
		return "hand"
	if b.contains("shoulder"):
		return "shoulder"
	if b.ends_with("arm"):
		return "arm"
	if b.contains("upleg"):
		return "upleg"
	if b.ends_with("leg"):
		return "leg"
	if b.contains("foot") or b.contains("toe"):
		return "foot"
	if b.contains("hips"):
		return "hips"
	if b.contains("spine"):
		return "spine"
	return "skin"     # neck, head


func _palette() -> Dictionary:
	if outfit == "winai":
		# ครู: เสื้อข้าราชการสีกากี (แขนสั้น) กางเกงสแลคสีดำ รองเท้าหนัง
		return {
			"skin": SKIN_WINAI, "hand": SKIN_WINAI, "forearm": SKIN_WINAI,
			"spine": KHAKI, "shoulder": KHAKI, "arm": KHAKI,
			"hips": SLACKS, "upleg": SLACKS, "leg": SLACKS, "foot": BLACK,
		}
	# มิว: นักเรียนชาย เสื้อนักเรียนสีขาวแขนสั้น กางเกงขาสั้นสีกรมท่า ถุงเท้าขาว รองเท้าผ้าใบดำ
	return {
		"skin": SKIN_MIW, "hand": SKIN_MIW, "forearm": SKIN_MIW,
		"spine": UNI_WHITE, "shoulder": UNI_WHITE, "arm": UNI_WHITE,
		"hips": SKIRT_NAVY, "upleg": SKIRT_NAVY, "leg": SKIN_MIW, "foot": UNI_WHITE,
	}


# ------------------------------------------------------------------- miw
func _dress_miw() -> void:
	# กระเป๋าสะพายหลัง (ดำ) + สายสะพาย
	_attach_box("Spine2", Vector3(0.0, -0.08, -0.15), Vector3(0.30, 0.38, 0.14), Color(0.16, 0.18, 0.30))
	_attach_box("Spine2", Vector3(0.0, -0.17, -0.20), Vector3(0.20, 0.14, 0.05), Color(0.95, 0.75, 0.2))
	_attach_box("Spine2", Vector3(0.105, 0.02, 0.0), Vector3(0.045, 0.30, 0.20), Color(0.16, 0.18, 0.30))
	_attach_box("Spine2", Vector3(-0.105, 0.02, 0.0), Vector3(0.045, 0.30, 0.20), Color(0.16, 0.18, 0.30))
	# เข็มขัดหนังดำ + หัวเข็มขัดเงิน
	_attach_mesh("Hips", Vector3(0.0, 0.05, 0.0), _cone(0.150, 0.150, 0.04), BLACK)
	_attach_box("Hips", Vector3(0.0, 0.05, 0.148), Vector3(0.040, 0.034, 0.012), Color(0.85, 0.85, 0.88))
	# ถุงเท้าขาวยาวครึ่งน่อง
	for side in ["Left", "Right"]:
		_seg(side + "Leg", side + "Foot", 0.052, UNI_WHITE, 0.50, 1.0)
	# ป้ายชื่อ และขอบปกเสื้อ
	_attach_box("Spine2", Vector3(0.055, 0.015, 0.113), Vector3(0.055, 0.032, 0.012), Color(0.98, 0.82, 0.25))
	for sx in [-1.0, 1.0]:
		_attach_box("Spine2", Vector3(sx * 0.040, 0.100, 0.100), Vector3(0.060, 0.030, 0.018), UNI_WHITE.darkened(0.08), Vector3(0, 0, sx * 28.0))
	_build_shoes(BLACK, UNI_WHITE)
	_build_head(HAIR_MIW, false)


# ----------------------------------------------------------------- winai
func _dress_winai() -> void:
	# เข็มขัดหนัง + หัวเข็มขัดทอง
	_attach_mesh("Hips", Vector3(0.0, 0.06, 0.0), _cone(0.155, 0.155, 0.045), Color(0.10, 0.08, 0.07))
	_attach_box("Hips", Vector3(0.0, 0.06, 0.150), Vector3(0.050, 0.040, 0.014), Color(0.95, 0.78, 0.25))
	# สายคล้องบัตรข้าราชการ + บัตร + เข็มกลัดอกซ้าย
	for sx in [-1.0, 1.0]:
		_attach_box("Spine2", Vector3(sx * 0.046, 0.085, 0.100), Vector3(0.016, 0.20, 0.010), Color(0.90, 0.25, 0.25), Vector3(0, 0, sx * -12.0))
	_attach_box("Spine1", Vector3(0.0, 0.050, 0.130), Vector3(0.060, 0.082, 0.012), UNI_WHITE)
	_attach_box("Spine1", Vector3(0.0, 0.074, 0.137), Vector3(0.040, 0.020, 0.006), Color(0.2, 0.3, 0.7))
	_attach_box("Spine2", Vector3(-0.070, 0.050, 0.110), Vector3(0.030, 0.030, 0.010), Color(0.95, 0.78, 0.25))
	# ปกเสื้อ + กระเป๋าเสื้อ + บ่าประดับ
	for sx in [-1.0, 1.0]:
		_attach_box("Spine2", Vector3(sx * 0.045, 0.105, 0.098), Vector3(0.070, 0.036, 0.020), KHAKI.lightened(0.12), Vector3(0, 0, sx * 30.0))
		_attach_box("Spine2", Vector3(sx * 0.115, 0.095, 0.0), Vector3(0.070, 0.012, 0.120), Color(0.30, 0.25, 0.15))
	_attach_box("Spine1", Vector3(0.080, -0.010, 0.128), Vector3(0.070, 0.070, 0.010), KHAKI.darkened(0.10))
	# ไม้เรียวในมือขวา
	_attach_box("RightHand", Vector3(0.0, 0.0, 0.0), Vector3(0.05, 0.05, 0.42), WOOD, Vector3(0, 0, 0), true)
	_build_shoes(BLACK, Color(0.18, 0.14, 0.12))
	_build_head(HAIR_WINAI, true)


# ----------------------------------------------------------------- shoes
func _build_shoes(col: Color, sole: Color = Color(0, 0, 0, 0)) -> void:
	for side in ["Left", "Right"]:
		_attach_mesh(side + "Foot", Vector3(0.0, -0.040, 0.075), _sphere(0.5), col, Vector3(0.115, 0.085, 0.29))
		if sole.a > 0.0:
			_attach_mesh(side + "Foot", Vector3(0.0, -0.075, 0.075), _sphere(0.5), sole, Vector3(0.121, 0.030, 0.30))


# ------------------------------------------------------------------ head
## หน้า ผม (และแว่น+หนวดสำหรับครู) ผูกกับกระดูก Head
func _build_head(hair_col: Color, is_teacher: bool) -> void:
	var skin := SKIN_WINAI if is_teacher else SKIN_MIW
	# หมายเหตุ: หน่วยเป็นเมตรของโมเดลเดิม (ก่อนย่อ/ขยายด้วย _scale_k)
	var r := 0.112
	_attach_mesh("Head", Vector3(0, 0.08, 0.012), _sphere(r), skin)
	# หู
	for sx in [-1.0, 1.0]:
		_attach_mesh("Head", Vector3(sx * 0.108, 0.080, 0.0), _sphere(0.022), skin.darkened(0.04), Vector3(0.6, 1.0, 0.8))
	# ตา (มีไฮไลต์) คิ้ว ปาก จมูก แก้ม
	for sx in [-1.0, 1.0]:
		_attach_mesh("Head", Vector3(sx * 0.042, 0.095, 0.092), _sphere(0.021), WHITE, Vector3(1, 1.2, 0.6))
		_attach_mesh("Head", Vector3(sx * 0.042, 0.095, 0.108), _sphere(0.013), Color(0.06, 0.04, 0.04), Vector3(1, 1.15, 0.6))
		_attach_mesh("Head", Vector3(sx * 0.038, 0.101, 0.118), _sphere(0.004), WHITE)
		_attach_box("Head", Vector3(sx * 0.044, 0.130, 0.098), Vector3(0.046, 0.009, 0.012), hair_col.darkened(0.2), Vector3(0, 0, sx * -6.0))
	_attach_mesh("Head", Vector3(0.0, 0.070, 0.112), _sphere(0.013), skin.darkened(0.06))
	if is_teacher:
		# ปากยิ้มบาง ๆ ใต้หนวด
		_attach_box("Head", Vector3(0.0, 0.028, 0.103), Vector3(0.046, 0.007, 0.010), Color(0.62, 0.28, 0.26))
		# ผมสั้นเรียบร้อย แสกข้าง ซอยข้างสีดอกเลา + หนวดเรียบ ๆ
		_attach_mesh("Head", Vector3(0.0, 0.128, -0.012), _sphere(0.120), hair_col, Vector3(1.0, 0.60, 1.06))
		_attach_mesh("Head", Vector3(-0.030, 0.158, 0.040), _sphere(0.060), hair_col, Vector3(1.4, 0.5, 0.9), Vector3(0, 0, 14))
		for sx in [-1.0, 1.0]:
			_attach_mesh("Head", Vector3(sx * 0.100, 0.100, -0.010), _sphere(0.030), Color(0.55, 0.55, 0.58), Vector3(0.6, 1.1, 1.1))
		_attach_mesh("Head", Vector3(0.0, 0.050, 0.108), _sphere(0.036), hair_col, Vector3(2.0, 0.34, 0.5))
		# แว่นกรอบดำ
		for sx in [-1.0, 1.0]:
			_attach_mesh("Head", Vector3(sx * 0.044, 0.097, 0.112), _torus(0.020, 0.027), BLACK, Vector3(1, 1, 1), Vector3(90, 0, 0))
		_attach_box("Head", Vector3(0.0, 0.100, 0.114), Vector3(0.030, 0.006, 0.006), BLACK)
	else:
		# ปากยิ้ม
		_attach_box("Head", Vector3(0.0, 0.030, 0.104), Vector3(0.052, 0.008, 0.010), Color(0.82, 0.30, 0.32))
		# ผมดำสั้นทรงนักเรียน (รองทรง) หน้าม้าเรียบ ๆ
		_attach_mesh("Head", Vector3(0.0, 0.118, -0.016), _sphere(0.124), hair_col, Vector3(1.0, 0.70, 1.06))
		_attach_mesh("Head", Vector3(0.0, 0.158, 0.046), _sphere(0.058), hair_col, Vector3(1.7, 0.36, 0.60))
		for sx in [-1.0, 1.0]:
			_attach_mesh("Head", Vector3(sx * 0.100, 0.085, -0.020), _sphere(0.034), hair_col, Vector3(0.6, 1.2, 1.1))


# ----------------------------------------------------- primitive builders
func _sphere(r: float) -> Mesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 14
	m.rings = 8
	return m


func _cone(top: float, bottom: float, h: float) -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 16
	m.rings = 1
	return m


func _torus(inner: float, outer: float) -> Mesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 14
	m.ring_segments = 6
	return m


func _mat(c: Color, rough := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


## ท่อนยาวเชื่อมสองกระดูก (แขน ขา ลำตัว) — a, b = ชื่อกระดูก (ไม่ต้องมี mixamorig_)
## t0..t1 = ช่วงของเส้นจาก a ไป b, scale = สัดส่วนบีบ x/z, offset = ขยับในพิกัดโมเดล
func _seg(a: String, b: String, radius: float, col: Color, t0 := 0.0, t1 := 1.0,
		squash := Vector2.ONE, offset := Vector3.ZERO) -> void:
	var m := CapsuleMesh.new()
	m.radius = 0.5
	m.height = 1.0
	m.radial_segments = 14
	m.rings = 4
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = _mat(col)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	skeleton.add_child(mi)
	_segments.append({
		"mi": mi, "a": _bone_idx(a), "b": _bone_idx(b), "r": radius,
		"t0": t0, "t1": t1, "sq": squash, "off": offset,
	})


func _attach_mesh(bone: String, offset: Vector3, mesh: Mesh, col: Color,
		sc := Vector3.ONE, rot_deg := Vector3.ZERO, flat := false) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(col)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	skeleton.add_child(mi)
	_attachments.append({
		"mi": mi, "bone": _bone_idx(bone), "off": offset, "sc": sc,
		"rot": Basis.from_euler(rot_deg * (PI / 180.0)), "flat": flat,
	})


func _attach_box(bone: String, offset: Vector3, size: Vector3, col: Color,
		rot_deg := Vector3.ZERO, flat := false) -> void:
	var m := BoxMesh.new()
	m.size = size
	_attach_mesh(bone, offset, m, col, Vector3.ONE, rot_deg, flat)


# ------------------------------------------------------------ per-frame
func _update_attachments() -> void:
	if skeleton == null:
		return
	for s in _segments:
		var ia: int = s["a"]
		var ib: int = s["b"]
		if ia < 0 or ib < 0:
			continue
		var pa := skeleton.get_bone_global_pose(ia).origin
		var pb := skeleton.get_bone_global_pose(ib).origin
		var p0: Vector3 = pa.lerp(pb, s["t0"]) + (s["off"] as Vector3)
		var p1: Vector3 = pa.lerp(pb, s["t1"]) + (s["off"] as Vector3)
		var d := p1 - p0
		var mi: MeshInstance3D = s["mi"]
		var len := d.length()
		var r: float = s["r"]
		var sq: Vector2 = s["sq"]
		if len < 0.0005:
			# ก้อนกลม (เช่น สะโพก) — ไม่มีทิศ ใช้แนวตั้ง
			mi.transform = Transform3D(Basis.from_scale(Vector3(r * 2.0 * sq.x, r * 2.0, r * 2.0 * sq.y)), p0)
			continue
		var q := Quaternion(Vector3.UP, d.normalized())
		var basis := Basis(q) * Basis.from_scale(Vector3(r * 2.0 * sq.x, len + r * 1.2, r * 2.0 * sq.y))
		mi.transform = Transform3D(basis, (p0 + p1) * 0.5)

	for at in _attachments:
		var bi: int = at["bone"]
		if bi < 0:
			continue
		var pose := skeleton.get_bone_global_pose(bi)
		var rest := skeleton.get_bone_global_rest(bi)
		var delta := pose.basis * rest.basis.inverse()     # การหมุนจากท่าพัก
		var off: Vector3 = at["off"]
		var mi: MeshInstance3D = at["mi"]
		var basis: Basis = delta * (at["rot"] as Basis) * Basis.from_scale(at["sc"])
		var pos := pose.origin + delta * off
		if at["flat"]:
			# ไม้เรียวในมือ: ชี้ไปข้างหน้า-ขึ้นเล็กน้อย ไม่ขึ้นกับแกนของกระดูกมือ
			var fwd := Basis(Vector3.RIGHT, deg_to_rad(-25.0))
			basis = fwd * (at["rot"] as Basis) * Basis.from_scale(at["sc"])
			pos = pose.origin + Vector3(0.0, 0.0, 0.14)
		mi.transform = Transform3D(basis, pos)


# --------------------------------------------------------------- control
func play(anim_name: String, blend := 0.12, speed := 1.0, from := 0.0) -> void:
	if anim == null or not anim.has_animation(anim_name):
		return
	if _cur != anim_name or from > 0.0:
		anim.play(anim_name, blend)
		if from > 0.0:
			anim.seek(from, true)
		_cur = anim_name
	anim.speed_scale = speed


func current_animation() -> String:
	return _cur


# ---------------------------------------------------------------- helpers
func _bone_idx(short_name: String) -> int:
	var i := skeleton.find_bone("mixamorig_" + short_name)
	if i < 0:
		push_warning("ไม่พบกระดูก " + short_name)
	return i


func _bone_pos(short_name: String) -> Vector3:
	var i := _bone_idx(short_name)
	if i < 0:
		return Vector3.ZERO
	return skeleton.get_bone_global_rest(i).origin


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for c in node.get_children():
		var f := _find_anim_player(c)
		if f != null:
			return f
	return null


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for c in node.get_children():
		var f := _find_skeleton(c)
		if f != null:
			return f
	return null


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
