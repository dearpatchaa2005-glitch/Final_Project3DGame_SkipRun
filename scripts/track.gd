@tool
class_name Track
extends Node3D
## =====================================================================
##  สร้างถนนในเมืองไม่รู้จบ ตามเส้นทาง RoadPath (มีทั้งทางตรงและทางโค้ง)
##  แบ่งเป็นช่วง (chunk) ยาว 20 ม. สร้างข้างหน้าผู้เล่น ลบทิ้งข้างหลัง
##    - พื้นผิวถนน เส้นจราจร ทางเท้า ขอบทาง = เมชแบบริบบิ้นที่โค้งตามถนน
##    - ตึก ต้นไม้ เสาไฟ คนยืนข้างทาง ฯลฯ = วางเรียงตามเส้นทาง
##
##  ถ้ามี .glb ใน res://assets/city/buildings จะใช้เป็นตึกแทนทรงกล่องอัตโนมัติ
## =====================================================================

const CHUNK_LEN := 20.0
const ROAD_W := 7.4
const SIDEWALK_W := 2.6

const ASPHALT := Color(0.30, 0.31, 0.34)
const CONCRETE := Color(0.53, 0.52, 0.50)
const CURB := Color(0.92, 0.90, 0.86)
const LINE_WHITE := Color(0.95, 0.95, 0.92)
const LINE_YELLOW := Color(0.98, 0.82, 0.25)
const GROUND := Color(0.40, 0.41, 0.39)

@export var ahead := 150.0
@export var behind := 70.0

var path: RoadPath
var _chunks: Dictionary = {}
var _seed := 1
var _mat: StandardMaterial3D


func reset(new_seed := 0) -> void:
	for c in _chunks.values():
		(c as Node).queue_free()
	_chunks.clear()
	_seed = new_seed if new_seed != 0 else (randi() % 100000 + 1)


## เรียกทุกเฟรม: สร้างช่วงใหม่ให้ครบรอบระยะ s ของผู้เล่น
func update_for(s: float) -> void:
	var cur := int(floor(s / CHUNK_LEN))
	var lo := cur - int(ceil(behind / CHUNK_LEN))
	var hi := cur + int(ceil(ahead / CHUNK_LEN))
	for i in range(lo, hi + 1):
		if not _chunks.has(i):
			var c := _build_chunk(i)
			add_child(c)
			_chunks[i] = c
	for i in _chunks.keys():
		if i < lo - 1 or i > hi + 1:
			(_chunks[i] as Node).queue_free()
			_chunks.erase(i)


func _build_chunk(i: int) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([_seed, i])
	var c := Node3D.new()
	c.name = "Chunk%d" % i
	var s0 := i * CHUNK_LEN
	var sc := s0 + CHUNK_LEN * 0.5
	_add(c, _surface_mesh(i, s0), "Surface")

	# ---- ตึกสองฝั่ง ----
	for side in [-1.0, 1.0]:
		# ด้านซ้ายช่วงจุดเริ่มต้นเป็นพื้นที่โรงเรียน (school.gd) ไม่สร้างตึกทับ
		var in_school: bool = side < 0.0 and s0 >= -80.0 and s0 < 40.0
		if not in_school:
			_add_buildings(c, side, rng, s0)
		_add_roadside(c, side, rng, i, sc)
	return c


# ------------------------------------------------------------ พื้นผิวถนน
func _surface_mesh(i: int, s0: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var s1 := s0 + CHUNK_LEN
	var half := ROAD_W * 0.5
	var out_x := half + SIDEWALK_W
	var step := 5.0
	# พื้นดินรอบนอก (กันเห็นช่องว่างใต้ตึกบนทางโค้ง)
	_band(st, s0, s1, -48.0, -out_x, -0.06, GROUND, step)
	_band(st, s0, s1, out_x, 48.0, -0.06, GROUND, step)
	# ถนน
	_band(st, s0, s1, -half, half, 0.0, ASPHALT, step)
	# ทางเท้า + ขอบทาง
	for side in [-1.0, 1.0]:
		var a: float = half + 0.22
		var b: float = out_x
		if side < 0.0:
			_band(st, s0, s1, -b, -a, 0.12, CONCRETE, step)
			_band(st, s0, s1, -a, -half, 0.14, CURB, step)
			_wall(st, s0, s1, -half, 0.0, 0.14, CURB, 1.0, step)
		else:
			_band(st, s0, s1, a, b, 0.12, CONCRETE, step)
			_band(st, s0, s1, half, a, 0.14, CURB, step)
			_wall(st, s0, s1, half, 0.0, 0.14, CURB, -1.0, step)
	# เส้นขอบถนนสีเหลือง
	for sx in [-1.0, 1.0]:
		var xe: float = sx * (half - 0.18)
		_band(st, s0, s1, xe - 0.06, xe + 0.06, 0.012, LINE_YELLOW, step)
	# เส้นแบ่งเลน (ประขาว)
	var sc := s0 + CHUNK_LEN * 0.5
	for sx in [-1.1, 1.1]:
		for k in 3:
			var c := sc + (k - 1) * 6.6
			_band(st, c - 1.5, c + 1.5, sx - 0.07, sx + 0.07, 0.012, LINE_WHITE, 1.5)
	# ทางม้าลาย
	if i % 7 == 3:
		for k in 9:
			var cx := -3.2 + k * 0.8
			_band(st, sc - 1.6, sc + 1.6, cx - 0.25, cx + 0.25, 0.016, LINE_WHITE, 1.6)

	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _material() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.vertex_color_use_as_albedo = true
		_mat.vertex_color_is_srgb = true
		_mat.roughness = 0.95
	return _mat


## แถบแนวนอนที่โค้งตามถนน ระหว่างระยะเยื้อง xa < xb  (ด้านบนหันขึ้น)
func _band(st: SurfaceTool, s0: float, s1: float, xa: float, xb: float, y: float, col: Color, step: float) -> void:
	var n := maxi(1, int(ceil((s1 - s0) / step - 0.001)))
	var lift := Vector3(0, y, 0)
	for k in n:
		var sa := s0 + (s1 - s0) * k / n
		var sb := s0 + (s1 - s0) * (k + 1) / n
		var a_back_l := path.pos(sa, xa) + lift
		var b_back_r := path.pos(sa, xb) + lift
		var c_fwd_r := path.pos(sb, xb) + lift
		var d_fwd_l := path.pos(sb, xa) + lift
		_tri(st, a_back_l, d_fwd_l, c_fwd_r, col, Vector3.UP)
		_tri(st, a_back_l, c_fwd_r, b_back_r, col, Vector3.UP)


## แผงตั้งตามแนวถนนที่ระยะเยื้อง x (facing = +1 หันออกทางขวา, -1 หันทางซ้าย)
func _wall(st: SurfaceTool, s0: float, s1: float, x: float, y0: float, y1: float, col: Color, facing: float, step: float) -> void:
	var n := maxi(1, int(ceil((s1 - s0) / step - 0.001)))
	for k in n:
		var sa := s0 + (s1 - s0) * k / n
		var sb := s0 + (s1 - s0) * (k + 1) / n
		var pa := path.pos(sa, x)
		var pb := path.pos(sb, x)
		var yaw := path.yaw((sa + sb) * 0.5)
		var nrm := Vector3(cos(yaw), 0, -sin(yaw)) * facing
		var p00 := pa + Vector3(0, y0, 0)
		var p01 := pa + Vector3(0, y1, 0)
		var p11 := pb + Vector3(0, y1, 0)
		var p10 := pb + Vector3(0, y0, 0)
		if facing > 0.0:
			_tri(st, p00, p01, p11, col, nrm)
			_tri(st, p00, p11, p10, col, nrm)
		else:
			_tri(st, p10, p11, p01, col, nrm)
			_tri(st, p10, p01, p00, col, nrm)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color, nrm: Vector3) -> void:
	for v in [a, b, c]:
		st.set_color(col)
		st.set_normal(nrm)
		st.add_vertex(v)


# -------------------------------------------------------------- ตึกและของข้างทาง
## วางโหนดไว้ที่ระยะ s เยื้อง x หันตามถนน
func _place(parent: Node3D, n: Node3D, s: float, x: float, y: float, extra_yaw := 0.0) -> void:
	n.position = path.pos(s, x) + Vector3(0, y, 0)
	n.rotation.y = path.yaw(s) + extra_yaw
	parent.add_child(n)


func _add_buildings(c: Node3D, side: float, rng: RandomNumberGenerator, s0: float) -> void:
	var x0 := ROAD_W * 0.5 + SIDEWALK_W            # ขอบในของตึก
	var split := rng.randf() < 0.55                # แบ่งเป็นสองหลังต่อช่วง
	var count := 2 if split else 1
	var depth := CHUNK_LEN / count
	for k in count:
		var w := rng.randf_range(7.0, 11.0)
		var h := rng.randf_range(7.0, 24.0)
		var col := Props.BUILDING_COLORS[rng.randi() % Props.BUILDING_COLORS.size()]
		var s := s0 + depth * (k + 0.5)
		var node: Node3D = null
		var flip := 0.0
		if Props.has_external("buildings"):
			node = Props.external("buildings", rng, Vector3(w, h, depth - 0.4))
		if node == null:
			node = Props.building(w, depth - 0.3, h, col, true, rng)
			if depth > 9.0 and rng.randf() < 0.7:
				var texts := Props.FUNNY_SHOPS
				var sign_cols: Array[Color] = [Color(0.88, 0.2, 0.3), Color(0.15, 0.5, 0.8), Color(0.9, 0.5, 0.1), Color(0.2, 0.6, 0.35), Color(0.55, 0.25, 0.7)]
				node.add_child(Props.shop_face_sign(texts[rng.randi() % texts.size()], sign_cols[rng.randi() % sign_cols.size()], w, depth, 4.1))
			if side > 0.0:
				flip = PI      # ให้กันสาดหันเข้าถนนทั้งสองฝั่ง
		node.name = "Building"
		_place(c, node, s, side * (x0 + w * 0.5), 0.0, flip)


func _add(parent: Node, n: Node, nm: String) -> void:
	n.name = nm
	parent.add_child(n)


func _add_roadside(c: Node3D, side: float, rng: RandomNumberGenerator, idx: int, sc: float) -> void:
	var lamp_x: float = side * (ROAD_W * 0.5 + 0.55)
	# เสาไฟสลับฝั่งกันเป็นช่วง ๆ
	if (idx + (0 if side < 0.0 else 1)) % 2 == 0:
		var lamp := Props.street_lamp()
		lamp.name = "StreetLamp"
		if side > 0.0:
			lamp.scale.x = -1.0
		_place(c, lamp, sc + rng.randf_range(-6.0, 6.0), lamp_x, 0.12)
	# ต้นไม้
	if rng.randf() < 0.65:
		var t := Props.tree(rng)
		t.name = "Tree"
		t.scale = Vector3.ONE * rng.randf_range(0.85, 1.2)
		_place(c, t, sc + rng.randf_range(-8.0, 8.0), side * (ROAD_W * 0.5 + SIDEWALK_W - 0.6), 0.12)
	# ของจุกจิกริมทาง
	var r := rng.randf()
	if r < 0.22:
		var h := Props.hydrant()
		h.name = "Hydrant"
		_place(c, h, sc + rng.randf_range(-8.0, 8.0), side * (ROAD_W * 0.5 + 0.6), 0.12)
	elif r < 0.40:
		var b := Props.bin()
		b.name = "Bin"
		_place(c, b, sc + rng.randf_range(-8.0, 8.0), side * (ROAD_W * 0.5 + 1.0), 0.12)
	# ของตกแต่งจริงจาก Kenney (ไฟจราจร ป้ายหยุด ถังขยะใหญ่ พุ่มไม้ ดอกไม้)
	if rng.randf() < 0.55:
		var ke := Props.kenney_roadside(rng)
		if ke != null:
			ke.name = "KenneyProp"
			var ex: float = side * (ROAD_W * 0.5 + (0.8 if rng.randf() < 0.5 else SIDEWALK_W - 0.5))
			_place(c, ke, sc + rng.randf_range(-9.0, 9.0), ex, 0.12, (PI * 0.5 if side < 0.0 else -PI * 0.5) + rng.randf_range(-0.2, 0.2))
	# แม่ค้ารถเข็นริมทาง / คนหลับบนม้านั่ง / แมวจร (รายละเอียดตลก ๆ ระหว่างทาง)
	var fun := rng.randf()
	var face: float = PI * 0.5 if side < 0.0 else -PI * 0.5       # หันหน้าเข้าหาถนน
	if fun < 0.34:
		var umb: Array[Color] = [Color(0.95, 0.3, 0.35), Color(0.98, 0.7, 0.15), Color(0.25, 0.7, 0.85), Color(0.9, 0.4, 0.7)]
		var cart := Props.vendor_cart(Props.VENDOR_TEXTS[rng.randi() % Props.VENDOR_TEXTS.size()], umb[rng.randi() % umb.size()])
		cart.name = "VendorCart"
		_place(c, cart, sc + rng.randf_range(-5.0, 5.0), side * (ROAD_W * 0.5 + SIDEWALK_W * 0.62), 0.12, face)
	elif fun < 0.50:
		var sb := Props.sleepy_bench()
		sb.name = "SleepyBench"
		_place(c, sb, sc + rng.randf_range(-5.0, 5.0), side * (ROAD_W * 0.5 + SIDEWALK_W * 0.55), 0.12, face)
	elif fun < 0.68:
		var cat_cols: Array[Color] = [Color(0.95, 0.6, 0.25), Color(0.55, 0.55, 0.58), Color(0.95, 0.9, 0.8), Color(0.25, 0.22, 0.2)]
		var ct := Props.cat(cat_cols[rng.randi() % cat_cols.size()])
		ct.name = "StrayCat"
		_place(c, ct, sc + rng.randf_range(-6.0, 6.0), side * (ROAD_W * 0.5 + 1.2), 0.12, face + rng.randf_range(-0.6, 0.6))
	# คนยืนข้างทาง (ประดับ)
	if rng.randf() < 0.35:
		var shirts: Array[Color] = [Color(0.9, 0.5, 0.3), Color(0.35, 0.6, 0.8), Color(0.8, 0.3, 0.5), Color(0.5, 0.75, 0.4)]
		var p := Props.pedestrian(shirts[rng.randi() % shirts.size()])
		p.name = "Pedestrian"
		_place(c, p, sc + rng.randf_range(-8.0, 8.0), side * (ROAD_W * 0.5 + 1.5), 0.12, rng.randf_range(0.0, TAU))
