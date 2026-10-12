@tool
class_name Props
extends RefCounted
## =====================================================================
##  ตัวสร้างโมเดลฉากเมือง (ตึก รถ รถเมล์ คนเดินถนน สิ่งกีดขวาง ฯลฯ) ด้วยโค้ด
##
##  โปรเจกต์นี้รันได้ทันทีโดยไม่ต้องมีไฟล์โมเดลภายนอก (ทุกอย่างสร้างจาก
##  ทรงกล่อง/ทรงกระบอกง่าย ๆ สไตล์ low-poly)
##
##  ถ้าต้องการใช้ asset ของ Kenney (City Kit / City Builder Bits / City Props /
##  Prototype Kit — ใบอนุญาต CC0) ให้วางไฟล์ .glb ลงในโฟลเดอร์
##      res://assets/city/buildings/   ตึก อาคาร
##      res://assets/city/vehicles/    รถยนต์ รถเมล์ แท็กซี่
##      res://assets/city/props/       ต้นไม้ เสาไฟ ป้าย ฯลฯ (ของตกแต่งริมทาง)
##  เกมจะหยิบมาใช้แทนโมเดลที่สร้างจากโค้ดให้อัตโนมัติ (ดู README.md)
## =====================================================================

const ROAD_DIRS := {
	"buildings": "res://assets/city/buildings",
	"vehicles": "res://assets/city/vehicles",
	"props": "res://assets/city/props",
}

# ----- สีหลัก (โทนสดใสแบบเมืองยามเช้า) -----
const BUILDING_COLORS: Array[Color] = [
	Color(0.93, 0.72, 0.38), Color(0.93, 0.48, 0.42), Color(0.42, 0.78, 0.68),
	Color(0.95, 0.80, 0.32), Color(0.42, 0.62, 0.92), Color(0.88, 0.52, 0.72),
	Color(0.66, 0.56, 0.88), Color(0.58, 0.80, 0.42),
]
const CAR_COLORS: Array[Color] = [
	Color(0.95, 0.80, 0.15), Color(0.90, 0.25, 0.28), Color(0.25, 0.55, 0.90),
	Color(0.95, 0.55, 0.75), Color(0.30, 0.75, 0.55), Color(0.92, 0.92, 0.92),
]
const SIGN_TEXTS: Array[String] = [
	"ก๋วยเตี๋ยวเรือ", "ข้าวมันไก่", "ชานมไข่มุก", "ตัดผมชาย", "ปาท่องโก๋", "ร้านโชห่วย", "น้ำเต้าหู้",
]
## ป้ายร้านตลก ๆ บนตึกริมถนน (ของกินยามเช้า / ร้านแถวโรงเรียน)
const FUNNY_SHOPS: Array[String] = [
	"กาแฟอุ่นใจ", "ข้าวมันไก่ปลุกใจ", "เครื่องเขียนลุงเฮง", "หมูปิ้งนมสดป้าหน่อย",
	"ตัดผมทรงนักเรียน", "ปาท่องโก๋ร้อน ๆ", "ซ่อมจักรยานด่วน", "ข้าวเหนียวมะม่วงป้าสม",
	"ชุดนักเรียนราคาประหยัด", "ชาไข่มุกแก้ง่วง", "โชห่วยลุงสมชาย", "โจ๊กหมูตื่นเช้า",
]
## ข้อความบนรถเข็นแม่ค้า
const VENDOR_TEXTS: Array[String] = [
	"หมูปิ้ง 10฿", "ไข่ปิ้ง", "ปาท่องโก๋", "ชาเย็น", "กาแฟโบราณ", "ข้าวเหนียวหมูปิ้ง", "น้ำเต้าหู้",
]
## คำพูดของคนเดินถนนข้างทาง
const WALKER_SAYS: Array[String] = [
	"ง่วงจัง...", "ขอกาแฟก่อน", "ไปไหนน่ะ?", "อ้าว มิว!", "ไม่ไปเรียนเหรอ?", "เดินช้า ๆ สิ", "ขอทางหน่อย!", "หิวข้าว",
]

static var _mat_cache: Dictionary = {}
static var _mesh_cache: Dictionary = {}
static var _window_tex: ImageTexture
static var _external: Dictionary = {}
static var _external_scanned := false


# ----------------------------------------------------------------- helpers
static func mat(c: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var key := "%s_%s_%s" % [c.to_html(true), rough, metal]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	_mat_cache[key] = m
	return m


static func glow_mat(c: Color, energy := 0.6) -> StandardMaterial3D:
	var key := "glow_%s_%s" % [c.to_html(true), energy]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.35
	m.metallic = 0.3
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	_mat_cache[key] = m
	return m


static func box(size: Vector3, c: Color, pos := Vector3.ZERO, rough := 0.85) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var key := "box_%s" % [size]
	var bm: BoxMesh
	if _mesh_cache.has(key):
		bm = _mesh_cache[key]
	else:
		bm = BoxMesh.new()
		bm.size = size
		_mesh_cache[key] = bm
	mi.mesh = bm
	mi.material_override = mat(c, rough)
	mi.position = pos
	return mi


static func cyl(radius: float, height: float, c: Color, pos := Vector3.ZERO, seg := 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = seg
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat(c)
	mi.position = pos
	return mi


static func ball(radius: float, c: Color, pos := Vector3.ZERO, squash := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = mat(c)
	mi.position = pos
	mi.scale = squash
	return mi


## ลายหน้าต่าง 1 ช่อง (ขาว = ผนัง ฟ้าเข้ม = กระจก) ใช้ซ้ำแบบ triplanar กับทุกตึก
static func window_texture() -> ImageTexture:
	if _window_tex != null:
		return _window_tex
	var w := 64
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1))
	img.fill_rect(Rect2i(14, 14, 36, 36), Color(0.93, 0.93, 0.93))      # กรอบ
	img.fill_rect(Rect2i(17, 17, 30, 30), Color(0.36, 0.50, 0.62))      # กระจก
	img.fill_rect(Rect2i(17, 17, 30, 9), Color(0.55, 0.70, 0.80))       # แสงสะท้อน
	img.fill_rect(Rect2i(31, 17, 2, 30), Color(0.93, 0.93, 0.93))       # คั่นกลาง
	img.fill_rect(Rect2i(10, 50, 44, 4), Color(0.80, 0.80, 0.80))       # ขอบหน้าต่าง
	img.generate_mipmaps()
	_window_tex = ImageTexture.create_from_image(img)
	return _window_tex


# ---------------------------------------------------------------- building
## ตึกแถว/อาคารพาณิชย์ — origin อยู่กลางฐาน (y=0 คือพื้น)
static func building(w: float, d: float, h: float, c: Color, with_awning := true, rng: RandomNumberGenerator = null) -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, h, d)
	body.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = window_texture()
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(1.0 / 3.0, 1.0 / 3.4, 1.0 / 3.0)
	m.roughness = 0.9
	body.material_override = m
	body.position.y = h * 0.5
	root.add_child(body)
	# หลังคา
	root.add_child(box(Vector3(w + 0.3, 0.35, d + 0.3), c.darkened(0.45), Vector3(0, h + 0.17, 0)))
	if rng != null and rng.randf() < 0.55:
		root.add_child(cyl(0.9, 1.6, Color(0.55, 0.38, 0.28), Vector3(rng.randf_range(-w * 0.25, w * 0.25), h + 1.1, rng.randf_range(-d * 0.25, d * 0.25)), 8))
	# ชั้นล่างเป็นร้านค้า: กันสาดลายทาง
	if with_awning:
		var col := Color(0.92, 0.28, 0.30) if (rng == null or rng.randf() < 0.5) else Color(0.28, 0.62, 0.85)
		root.add_child(box(Vector3(0.9, 0.12, d * 0.8), col, Vector3(0, 3.0, 0)))
	return root


# ----------------------------------------------------------------- vehicles
## รถเก๋ง/แท็กซี่ — หัวรถหันไปทาง +Z (วิ่งสวนผู้เล่น) ขนาด ~1.9 x 1.5 x 4.2
static func car(c: Color) -> Node3D:
	var root := Node3D.new()
	root.add_child(box(Vector3(1.85, 0.62, 4.2), c, Vector3(0, 0.62, 0), 0.5))
	root.add_child(box(Vector3(1.60, 0.58, 2.1), c.lightened(0.08), Vector3(0, 1.20, -0.15), 0.5))
	# กระจก
	root.add_child(box(Vector3(1.64, 0.40, 1.9), Color(0.20, 0.28, 0.36), Vector3(0, 1.22, -0.15), 0.2))
	root.add_child(box(Vector3(1.66, 0.50, 0.05), Color(0.25, 0.35, 0.45), Vector3(0, 1.20, 0.92), 0.2))
	# ไฟหน้า / กันชน
	for sx in [-1.0, 1.0]:
		root.add_child(box(Vector3(0.32, 0.18, 0.06), Color(1.0, 0.96, 0.75), Vector3(sx * 0.62, 0.72, 2.12)))
		root.add_child(box(Vector3(0.30, 0.16, 0.06), Color(0.9, 0.1, 0.1), Vector3(sx * 0.62, 0.72, -2.12)))
	root.add_child(box(Vector3(1.9, 0.14, 0.14), Color(0.25, 0.25, 0.28), Vector3(0, 0.38, 2.14)))
	# ล้อ
	for sx in [-0.93, 0.93]:
		for sz in [-1.3, 1.3]:
			var wheel := cyl(0.34, 0.26, Color(0.08, 0.08, 0.09), Vector3(sx, 0.34, sz), 12)
			wheel.rotation_degrees = Vector3(0, 0, 90)
			root.add_child(wheel)
	return root


## รถเมล์ — ครีม-แดง ขนาด ~2.5 x 3.0 x 9.5
static func bus() -> Node3D:
	var root := Node3D.new()
	var cream := Color(0.97, 0.93, 0.82)
	var red := Color(0.85, 0.18, 0.20)
	root.add_child(box(Vector3(2.5, 2.7, 9.4), cream, Vector3(0, 1.75, 0), 0.6))
	root.add_child(box(Vector3(2.54, 0.9, 9.44), red, Vector3(0, 0.75, 0), 0.6))
	root.add_child(box(Vector3(2.56, 0.85, 8.4), Color(0.22, 0.32, 0.42), Vector3(0, 2.15, -0.2), 0.2))
	root.add_child(box(Vector3(2.3, 1.0, 0.06), Color(0.25, 0.36, 0.46), Vector3(0, 2.2, 4.72), 0.2))
	root.add_child(box(Vector3(2.0, 0.34, 0.06), Color(1.0, 0.85, 0.2), Vector3(0, 3.0, 4.72), 0.4))   # ป้ายสายรถ
	for sx in [-1.0, 1.0]:
		root.add_child(box(Vector3(0.36, 0.2, 0.06), Color(1.0, 0.96, 0.75), Vector3(sx * 0.9, 0.85, 4.72)))
	_bus_passengers(root)
	for sx in [-1.25, 1.25]:
		for sz in [-3.1, 3.1]:
			var wheel := cyl(0.52, 0.34, Color(0.08, 0.08, 0.09), Vector3(sx, 0.52, sz), 12)
			wheel.rotation_degrees = Vector3(0, 0, 90)
			root.add_child(wheel)
	return root


## รถเมล์แน่นเอี๊ยด: หน้าผู้โดยสารแนบกระจก มือโผล่ออกหน้าต่าง ป้ายหน้ารถ
static func _bus_passengers(root: Node3D) -> void:
	var skins: Array[Color] = [Color(0.95, 0.74, 0.6), Color(0.85, 0.62, 0.45), Color(0.98, 0.82, 0.68), Color(0.7, 0.5, 0.36)]
	var hairs: Array[Color] = [Color(0.12, 0.09, 0.07), Color(0.3, 0.2, 0.12), Color(0.1, 0.1, 0.12)]
	var idx := 0
	for sx in [-1.0, 1.0]:
		for k in 7:
			var z := -3.4 + k * 1.13
			var skin := skins[(idx + k) % skins.size()]
			root.add_child(ball(0.26, skin, Vector3(sx * 1.22, 2.18 + 0.05 * ((k + idx) % 3), z), Vector3(0.65, 1.0, 1.0)))
			root.add_child(ball(0.27, hairs[(k + idx) % hairs.size()], Vector3(sx * 1.2, 2.32 + 0.05 * ((k + idx) % 3), z), Vector3(0.6, 0.55, 1.0)))
			# ตาสองข้าง (แนบกระจกแบน ๆ)
			for ez in [-0.09, 0.09]:
				root.add_child(box(Vector3(0.03, 0.06, 0.05), Color(0.1, 0.1, 0.12), Vector3(sx * 1.31, 2.2 + 0.05 * ((k + idx) % 3), z + ez)))
		idx += 3
	# มือโบกออกจากหน้าต่าง 2 คน
	root.add_child(box(Vector3(0.45, 0.12, 0.12), Color(0.95, 0.74, 0.6), Vector3(1.55, 2.0, 1.2)))
	root.add_child(box(Vector3(0.45, 0.12, 0.12), Color(0.95, 0.74, 0.6), Vector3(-1.55, 1.9, -2.0)))
	var font := load("res://fonts/Kanit_600SemiBold.ttf") as Font
	var lb := Label3D.new()
	lb.text = "สาย 8 แน่นเอี๊ยด!"
	lb.font = font
	lb.font_size = 64
	lb.pixel_size = 0.0052
	lb.modulate = Color(0.2, 0.1, 0.0)
	lb.position = Vector3(0, 3.0, 4.77)
	root.add_child(lb)
	var lb2 := Label3D.new()
	lb2.text = "ยังไม่เต็มนะ!"
	lb2.font = font
	lb2.font_size = 52
	lb2.pixel_size = 0.0050
	lb2.modulate = Color(1, 1, 1)
	lb2.outline_size = 8
	lb2.outline_modulate = Color(0.5, 0.05, 0.08)
	lb2.position = Vector3(1.29, 0.8, 0.0)
	lb2.rotation_degrees = Vector3(0, 90, 0)
	root.add_child(lb2)
	var lb3 := lb2.duplicate() as Label3D
	lb3.position = Vector3(-1.29, 0.8, 0.0)
	lb3.rotation_degrees = Vector3(0, -90, 0)
	root.add_child(lb3)


# ------------------------------------------------------------- pedestrians
## คนเดินถนน (หันหน้าไปทาง +Z) สูง ~1.7
static func pedestrian(shirt: Color, hair := Color(0.15, 0.1, 0.08)) -> Node3D:
	var root := Node3D.new()
	var skin := Color(0.95, 0.74, 0.6)
	root.add_child(box(Vector3(0.52, 0.62, 0.30), shirt, Vector3(0, 1.14, 0)))
	root.add_child(ball(0.17, skin, Vector3(0, 1.64, 0)))
	root.add_child(ball(0.18, hair, Vector3(0, 1.69, -0.03), Vector3(1, 0.7, 1)))
	root.add_child(box(Vector3(0.20, 0.82, 0.22), Color(0.2, 0.22, 0.3), Vector3(-0.14, 0.41, 0)))
	root.add_child(box(Vector3(0.20, 0.82, 0.22), Color(0.2, 0.22, 0.3), Vector3(0.14, 0.41, 0)))
	root.add_child(box(Vector3(0.12, 0.55, 0.14), skin, Vector3(-0.32, 1.12, 0)))
	root.add_child(box(Vector3(0.12, 0.55, 0.14), skin, Vector3(0.32, 1.12, 0)))
	return root


# ------------------------------------------------------ low obstacles (jump)
static func cone(pos := Vector3.ZERO) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	var kc := named("roads", "construction-cone", 0.75)
	if kc != null:
		root.add_child(kc)
		return root
	var cm := CylinderMesh.new()
	cm.top_radius = 0.03
	cm.bottom_radius = 0.24
	cm.height = 0.62
	cm.radial_segments = 10
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = mat(Color(1.0, 0.45, 0.10))
	mi.position.y = 0.31
	root.add_child(mi)
	root.add_child(box(Vector3(0.56, 0.05, 0.56), Color(0.15, 0.15, 0.17), Vector3(0, 0.025, 0)))
	root.add_child(cyl(0.135, 0.09, Color(1, 1, 1), Vector3(0, 0.30, 0), 10))
	return root


static func barrier(width: float) -> Node3D:
	var root := Node3D.new()
	if has_named("roads", "construction-barrier"):
		var n2 := maxi(1, int(round(width / 1.2)))
		for i in n2:
			var kb := named("roads", "construction-barrier", 0.95)
			kb.position.x = -width * 0.5 + width / n2 * (i + 0.5)
			root.add_child(kb)
		return root
	var red := Color(0.90, 0.22, 0.20)
	var white := Color(0.97, 0.97, 0.97)
	var n := maxi(2, int(round(width / 0.5)))
	var seg := width / n
	root.add_child(box(Vector3(width, 0.06, 0.5), Color(0.2, 0.2, 0.22), Vector3(0, 0.03, 0)))
	for i in n:
		var col := red if i % 2 == 0 else white
		root.add_child(box(Vector3(seg, 0.28, 0.14), col, Vector3(-width * 0.5 + seg * (i + 0.5), 0.52, 0)))
	for sx in [-1.0, 1.0]:
		root.add_child(box(Vector3(0.10, 0.5, 0.10), Color(0.25, 0.25, 0.28), Vector3(sx * (width * 0.5 - 0.1), 0.25, 0)))
	return root


static func crates() -> Node3D:
	var root := Node3D.new()
	if has_named("carkit", "box"):
		var b1 := named("carkit", "box", 0.75)
		b1.position = Vector3(-0.4, 0, 0)
		root.add_child(b1)
		var b2 := named("carkit", "box", 0.6)
		b2.position = Vector3(0.45, 0, 0.05)
		b2.rotation.y = 0.5
		root.add_child(b2)
		return root
	var wood := Color(0.72, 0.52, 0.28)
	root.add_child(box(Vector3(0.9, 0.7, 0.8), wood, Vector3(-0.3, 0.35, 0)))
	root.add_child(box(Vector3(0.7, 0.55, 0.7), wood.darkened(0.1), Vector3(0.5, 0.275, 0.05)))
	root.add_child(box(Vector3(0.92, 0.06, 0.82), wood.darkened(0.3), Vector3(-0.3, 0.35, 0)))
	return root


static func trash_bags() -> Node3D:
	var root := Node3D.new()
	var blk := Color(0.10, 0.10, 0.12)
	root.add_child(ball(0.42, blk, Vector3(-0.3, 0.36, 0), Vector3(1, 0.85, 1)))
	root.add_child(ball(0.36, Color(0.16, 0.16, 0.2), Vector3(0.35, 0.31, 0.05), Vector3(1, 0.9, 1)))
	return root


static func bench(width := 1.8) -> Node3D:
	var root := Node3D.new()
	var wood := Color(0.62, 0.40, 0.22)
	root.add_child(box(Vector3(width, 0.08, 0.5), wood, Vector3(0, 0.46, 0)))
	root.add_child(box(Vector3(width, 0.36, 0.07), wood, Vector3(0, 0.72, -0.22)))
	for sx in [-1.0, 1.0]:
		root.add_child(box(Vector3(0.08, 0.46, 0.5), Color(0.2, 0.2, 0.22), Vector3(sx * (width * 0.5 - 0.1), 0.23, 0)))
	return root


# ------------------------------------------------------ high obstacles (duck)
## ป้ายร้านค้าที่ยื่นออกมา — ขอบล่างสูง 1.45 ม. มุดผ่านได้ถ้าก้ม
static func hanging_sign(width: float, text: String, col: Color) -> Node3D:
	var root := Node3D.new()
	root.add_child(box(Vector3(width, 0.75, 0.14), col, Vector3(0, 1.85, 0)))
	root.add_child(box(Vector3(width + 0.1, 0.06, 0.18), Color(0.2, 0.2, 0.22), Vector3(0, 2.25, 0)))
	var font := load("res://fonts/Kanit_600SemiBold.ttf") as Font
	for side in [1.0, -1.0]:
		var lb := Label3D.new()
		lb.text = text
		lb.font = font
		lb.font_size = 72
		lb.pixel_size = 0.0042
		lb.modulate = Color(1, 1, 1)
		lb.outline_size = 10
		lb.outline_modulate = Color(0.1, 0.1, 0.15)
		lb.position = Vector3(0, 1.85, side * 0.085)
		if side < 0.0:
			lb.rotation_degrees = Vector3(0, 180, 0)
		root.add_child(lb)
	# โซ่/เสาแขวนที่ขอบด้านข้าง (อยู่นอกเลน ไม่ชน)
	for sx in [-1.0, 1.0]:
		root.add_child(box(Vector3(0.07, 2.3, 0.07), Color(0.25, 0.25, 0.28), Vector3(sx * (width * 0.5 + 0.12), 1.15, 0)))
	return root


## ไม้กั้นทางข้าม (ลายขาว-แดง) — คานสูง 1.45 ม.
static func crossing_gate(width: float) -> Node3D:
	var root := Node3D.new()
	var n := maxi(3, int(round(width / 0.45)))
	var seg := width / n
	for i in n:
		var col := Color(0.92, 0.2, 0.2) if i % 2 == 0 else Color(0.98, 0.98, 0.98)
		root.add_child(box(Vector3(seg, 0.22, 0.12), col, Vector3(-width * 0.5 + seg * (i + 0.5), 1.62, 0)))
	for sx in [-1.0, 1.0]:
		root.add_child(box(Vector3(0.14, 1.75, 0.14), Color(0.25, 0.25, 0.3), Vector3(sx * (width * 0.5 + 0.1), 0.875, 0)))
		root.add_child(ball(0.1, Color(1.0, 0.15, 0.1), Vector3(sx * (width * 0.5 + 0.1), 1.82, 0)))
	return root


# --------------------------------------------------------------- roadside
static func street_lamp() -> Node3D:
	var root := Node3D.new()
	var steel := Color(0.30, 0.34, 0.38)
	root.add_child(cyl(0.07, 5.0, steel, Vector3(0, 2.5, 0), 8))
	root.add_child(box(Vector3(1.3, 0.07, 0.07), steel, Vector3(-0.55, 5.0, 0)))
	root.add_child(box(Vector3(0.45, 0.10, 0.22), Color(1.0, 0.95, 0.75), Vector3(-1.15, 4.95, 0)))
	return root


const KENNEY_TREES := ["tree_default", "tree_oak", "tree_fat", "tree_simple", "tree_small", "tree_thin"]

static func tree(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	if has_named("nature", "tree_oak"):
		var kt := named("nature", KENNEY_TREES[rng.randi() % KENNEY_TREES.size()], rng.randf_range(3.2, 4.6), rng.randf() * TAU)
		if kt != null:
			root.add_child(kt)
			return root
	root.add_child(cyl(0.14, 1.8, Color(0.42, 0.28, 0.18), Vector3(0, 0.9, 0), 6))
	var g := Color(0.28 + rng.randf() * 0.1, 0.62 + rng.randf() * 0.12, 0.28)
	root.add_child(ball(1.05, g, Vector3(0, 2.4, 0), Vector3(1, 0.95, 1)))
	root.add_child(ball(0.7, g.lightened(0.08), Vector3(0.55, 2.9, 0.2)))
	root.add_child(ball(0.62, g.darkened(0.06), Vector3(-0.5, 2.8, -0.2)))
	return root


static func hydrant() -> Node3D:
	var root := Node3D.new()
	root.add_child(cyl(0.16, 0.6, Color(0.88, 0.18, 0.15), Vector3(0, 0.3, 0), 8))
	root.add_child(ball(0.17, Color(0.88, 0.18, 0.15), Vector3(0, 0.62, 0)))
	root.add_child(box(Vector3(0.4, 0.1, 0.1), Color(0.88, 0.18, 0.15), Vector3(0, 0.42, 0)))
	return root


static func bin() -> Node3D:
	var root := Node3D.new()
	root.add_child(cyl(0.26, 0.8, Color(0.20, 0.45, 0.30), Vector3(0, 0.4, 0), 10))
	root.add_child(cyl(0.28, 0.06, Color(0.15, 0.35, 0.22), Vector3(0, 0.82, 0), 10))
	return root


# -------------------------------------------------------------------- coin
## เหรียญดาวความดี — ปริซึมรูปดาว 5 แฉก
## รถเข็นแม่ค้าริมทาง (หน้ารถเข็นหันไปทาง +Z) พร้อมร่มและป้ายราคา
static func vendor_cart(text: String, umbrella: Color) -> Node3D:
	var root := Node3D.new()
	var wood := Color(0.78, 0.52, 0.28)
	root.add_child(box(Vector3(1.5, 0.75, 0.9), wood, Vector3(0, 0.62, 0)))
	root.add_child(box(Vector3(1.56, 0.08, 0.96), Color(0.92, 0.9, 0.86), Vector3(0, 1.02, 0)))
	for sx in [-0.55, 0.55]:
		var w := cyl(0.3, 0.1, Color(0.15, 0.15, 0.17), Vector3(sx, 0.3, 0.0), 12)
		w.rotation_degrees = Vector3(0, 0, 90)
		root.add_child(w)
	root.add_child(cyl(0.3, 0.22, Color(0.25, 0.25, 0.28), Vector3(-0.35, 1.18, 0.0), 10))     # หม้อ/เตา
	root.add_child(box(Vector3(0.55, 0.05, 0.35), Color(0.35, 0.35, 0.38), Vector3(0.35, 1.08, 0.0)))
	root.add_child(box(Vector3(0.06, 1.7, 0.06), Color(0.85, 0.85, 0.88), Vector3(0.0, 1.9, -0.35)))   # เสาร่ม
	var um := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 1.35
	cm.height = 0.5
	cm.radial_segments = 8
	um.mesh = cm
	um.material_override = mat(umbrella, 0.7)
	um.position = Vector3(0, 2.95, -0.35)
	root.add_child(um)
	# แม่ค้าอยู่หลังรถเข็น
	var v := pedestrian(Color(0.97, 0.97, 0.95), Color(0.2, 0.15, 0.12))
	v.position = Vector3(0, 0, -0.8)
	v.rotation.y = PI
	root.add_child(v)
	var font := load("res://fonts/Kanit_600SemiBold.ttf") as Font
	root.add_child(box(Vector3(1.5, 0.4, 0.05), Color(0.15, 0.12, 0.1), Vector3(0, 0.62, 0.47)))
	var lb := Label3D.new()
	lb.text = text
	lb.font = font
	lb.font_size = 60
	lb.pixel_size = 0.0045
	lb.modulate = Color(1.0, 0.92, 0.4)
	lb.position = Vector3(0, 0.62, 0.5)
	root.add_child(lb)
	return root


## แมวจรจัดนั่งริมทาง
static func cat(c: Color) -> Node3D:
	var root := Node3D.new()
	root.add_child(ball(0.2, c, Vector3(0, 0.22, 0), Vector3(0.9, 1.0, 1.3)))
	root.add_child(ball(0.15, c, Vector3(0, 0.45, 0.2)))
	for sx in [-1.0, 1.0]:
		var ear := box(Vector3(0.07, 0.1, 0.05), c.darkened(0.15), Vector3(sx * 0.09, 0.6, 0.2))
		root.add_child(ear)
		root.add_child(box(Vector3(0.025, 0.04, 0.03), Color(0.1, 0.1, 0.1), Vector3(sx * 0.06, 0.47, 0.34)))
	var tail := box(Vector3(0.06, 0.06, 0.4), c.darkened(0.1), Vector3(0, 0.3, -0.35))
	tail.rotation_degrees = Vector3(-35, 0, 0)
	root.add_child(tail)
	return root


## คนงีบบนม้านั่ง มี Zzz ลอยอยู่
static func sleepy_bench() -> Node3D:
	var root := bench(1.8)
	var skin := Color(0.95, 0.74, 0.6)
	var torso := box(Vector3(0.5, 0.62, 0.3), Color(0.35, 0.55, 0.85), Vector3(0, 0.82, -0.12))
	torso.rotation_degrees = Vector3(0, 0, 14)
	root.add_child(torso)
	root.add_child(ball(0.17, skin, Vector3(0.12, 1.22, -0.05)))
	root.add_child(ball(0.18, Color(0.15, 0.1, 0.08), Vector3(0.13, 1.28, -0.08), Vector3(1, 0.7, 1)))
	root.add_child(box(Vector3(0.2, 0.2, 0.55), Color(0.2, 0.22, 0.3), Vector3(-0.14, 0.58, 0.25)))
	root.add_child(box(Vector3(0.2, 0.2, 0.55), Color(0.2, 0.22, 0.3), Vector3(0.14, 0.58, 0.25)))
	var lb := Label3D.new()
	lb.text = "Zzz..."
	lb.font = load("res://fonts/Kanit_600SemiBold.ttf") as Font
	lb.font_size = 64
	lb.pixel_size = 0.006
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.modulate = Color(1, 1, 1)
	lb.outline_size = 12
	lb.outline_modulate = Color(0.1, 0.1, 0.2)
	lb.position = Vector3(0.1, 1.85, 0)
	root.add_child(lb)
	return root


## ป้ายร้านตลก ๆ แปะบนผนังตึกด้านที่หันเข้าถนน (แกน +X ของตึก)
static func shop_face_sign(text: String, col: Color, w: float, depth: float, y: float) -> Node3D:
	var root := Node3D.new()
	var pw := minf(depth - 1.2, 8.0)
	root.add_child(box(Vector3(0.14, 1.0, pw), col, Vector3(w * 0.5 + 0.07, y, 0)))
	root.add_child(box(Vector3(0.16, 1.08, pw + 0.16), Color(1, 1, 1), Vector3(w * 0.5 + 0.06, y, 0)))
	root.add_child(box(Vector3(0.18, 0.96, pw - 0.04), col, Vector3(w * 0.5 + 0.08, y, 0)))
	var lb := Label3D.new()
	lb.text = text
	lb.font = load("res://fonts/Kanit_600SemiBold.ttf") as Font
	lb.font_size = 72
	lb.pixel_size = 0.0075
	lb.modulate = Color(1, 1, 1)
	lb.outline_size = 12
	lb.outline_modulate = Color(0.12, 0.1, 0.15)
	lb.width = pw * 130.0
	lb.autowrap_mode = TextServer.AUTOWRAP_OFF
	lb.position = Vector3(w * 0.5 + 0.2, y, 0)
	lb.rotation_degrees = Vector3(0, 90, 0)
	root.add_child(lb)
	return root


static func star_mesh(outer := 0.36, inner := 0.16, thick := 0.09) -> ArrayMesh:
	var key := "star_%s_%s_%s" % [outer, inner, thick]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var pts: Array[Vector2] = []
	for i in 10:
		var a := -PI * 0.5 + i * PI / 5.0
		var r := outer if i % 2 == 0 else inner
		pts.append(Vector2(cos(a) * r, -sin(a) * r))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hz := thick * 0.5
	for i in 10:
		var p0 := pts[i]
		var p1 := pts[(i + 1) % 10]
		# หน้า (+z) และหลัง (-z) — แบ่งเป็นสามเหลี่ยมจากจุดศูนย์กลาง
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(Vector3(0, 0, hz))
		st.add_vertex(Vector3(p0.x, p0.y, hz))
		st.add_vertex(Vector3(p1.x, p1.y, hz))
		st.set_normal(Vector3(0, 0, -1))
		st.add_vertex(Vector3(0, 0, -hz))
		st.add_vertex(Vector3(p1.x, p1.y, -hz))
		st.add_vertex(Vector3(p0.x, p0.y, -hz))
		# ด้านข้าง
		var e := p1 - p0
		var n := Vector3(e.y, -e.x, 0).normalized()
		st.set_normal(n)
		st.add_vertex(Vector3(p0.x, p0.y, hz))
		st.add_vertex(Vector3(p0.x, p0.y, -hz))
		st.add_vertex(Vector3(p1.x, p1.y, -hz))
		st.add_vertex(Vector3(p0.x, p0.y, hz))
		st.add_vertex(Vector3(p1.x, p1.y, -hz))
		st.add_vertex(Vector3(p1.x, p1.y, hz))
	var mesh := st.commit()
	_mesh_cache[key] = mesh
	return mesh


# ---------------------------------------------- external (Kenney) models
static func _collect(path: String, out: Array[PackedScene]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		var name := f.trim_suffix(".remap")
		if dir.current_is_dir():
			if not f.begins_with("."):
				_collect(path + "/" + f, out)
		elif name.ends_with(".glb") or name.ends_with(".gltf"):
			var ps := load("%s/%s" % [path, name]) as PackedScene
			if ps != null:
				out.append(ps)
		f = dir.get_next()
	dir.list_dir_end()


static func _scan_external() -> void:
	if _external_scanned:
		return
	_external_scanned = true
	for kind in ["buildings", "vehicles"]:
		var list: Array[PackedScene] = []
		_collect(ROAD_DIRS[kind], list)
		_external[kind] = list


## โหลดโมเดล Kenney ตามชื่อไฟล์ใน assets/city/props/<ชุด>/<ชื่อ>.glb
## ปรับขนาดให้สูง height เมตร (หรือพอดีกล่องถ้า height <= 0) วางฐานที่ y=0 กึ่งกลาง
static var _named: Dictionary = {}

static func named(pack: String, model: String, height: float, yaw := 0.0) -> Node3D:
	var path := "res://assets/city/props/%s/%s.glb" % [pack, model]
	if not _named.has(path):
		_named[path] = load(path) if ResourceLoader.exists(path) else null
	var ps := _named[path] as PackedScene
	if ps == null:
		return null
	var inst := ps.instantiate() as Node3D
	_tone_down(inst)
	var holder := Node3D.new()
	holder.add_child(inst)
	inst.rotation.y = yaw
	var b := _local_aabb(inst, inst)
	if b.size.y > 0.0001:
		var k := height / b.size.y
		inst.scale = Vector3.ONE * k
		inst.position = Vector3(-(b.position.x + b.size.x * 0.5) * k, -b.position.y * k, -(b.position.z + b.size.z * 0.5) * k)
	return holder


static func has_named(pack: String, model: String) -> bool:
	return ResourceLoader.exists("res://assets/city/props/%s/%s.glb" % [pack, model])


static func has_external(kind: String) -> bool:
	_scan_external()
	return _external.has(kind) and not (_external[kind] as Array).is_empty()


## หยิบโมเดลภายนอกแบบสุ่ม แล้วปรับขนาดให้พอดีกับกล่องเป้าหมาย (กว้าง x สูง x ยาว) วางฐานที่ y=0
static func external(kind: String, rng: RandomNumberGenerator, target: Vector3, fit_height := false) -> Node3D:
	_scan_external()
	var list: Array = _external.get(kind, [])
	if list.is_empty():
		return null
	var inst := (list[rng.randi() % list.size()] as PackedScene).instantiate() as Node3D
	_tone_down(inst)
	var holder := Node3D.new()
	holder.add_child(inst)
	var box_ := _local_aabb(inst, inst)
	if box_.size.x > 0.0001 and box_.size.y > 0.0001 and box_.size.z > 0.0001:
		var k := minf(target.x / box_.size.x, target.z / box_.size.z)
		if fit_height:
			k = target.y / box_.size.y
		inst.scale = Vector3.ONE * k
		inst.position = Vector3(-(box_.position.x + box_.size.x * 0.5) * k, -box_.position.y * k, -(box_.position.z + box_.size.z * 0.5) * k)
	return holder


## ลดความสว่างของวัสดุโมเดลภายนอก (สีขาวของ Kenney จ้าเกินเมื่อโดนแสงแดดตรง ๆ)
static var _toned: Dictionary = {}

static func _tone_down(root: Node) -> void:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh != null:
				for i in mi.mesh.get_surface_count():
					var m := mi.mesh.surface_get_material(i) as StandardMaterial3D
					if m == null:
						continue
					if not _toned.has(m):
						var d := m.duplicate() as StandardMaterial3D
						d.albedo_color = m.albedo_color * Color(0.8, 0.8, 0.82)
						d.roughness = 1.0
						_toned[m] = d
					mi.set_surface_override_material(i, _toned[m])
		for c in n.get_children():
			stack.append(c)


static func _local_aabb(node: Node, root: Node3D) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var xf := Transform3D.IDENTITY
			var cur: Node = mi
			while cur != null and cur != root.get_parent():
				if cur is Node3D:
					xf = (cur as Node3D).transform * xf
				cur = cur.get_parent()
			var b := xf * mi.get_aabb()
			if first:
				out = b
				first = false
			else:
				out = out.merge(b)
		for c in n.get_children():
			stack.append(c)
	return out


## ของตกแต่งริมทางจาก Kenney (City Kit Roads / Nature Kit) — คืน null ถ้าไม่มีไฟล์
static func kenney_roadside(rng: RandomNumberGenerator) -> Node3D:
	var r := rng.randf()
	if r < 0.20 and has_named("roads", "traffic-light"):
		return named("roads", "traffic-light", 4.2)
	if r < 0.34 and has_named("roads", "road-sign-stop"):
		return named("roads", "road-sign-stop", 2.4)
	if r < 0.44 and has_named("roads", "road-sign-warning"):
		return named("roads", "road-sign-warning", 2.4)
	if r < 0.60 and has_named("roads", "dumpster"):
		return named("roads", "dumpster", 1.3)
	if r < 0.82 and has_named("nature", "plant_bush"):
		var bn: Array[String] = ["plant_bush", "plant_bushLarge", "plant_bushSmall"]
		return named("nature", bn[rng.randi() % bn.size()], rng.randf_range(0.7, 1.2), rng.randf() * TAU)
	if has_named("nature", "flower_redA"):
		var fl: Array[String] = ["flower_redA", "flower_yellowA", "flower_purpleA"]
		return named("nature", fl[rng.randi() % fl.size()], 0.5, rng.randf() * TAU)
	return null
