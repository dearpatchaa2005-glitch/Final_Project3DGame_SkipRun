@tool
class_name School
extends Node3D
## =====================================================================
##  โรงเรียนมอดินแดง — ฉากเปิดเรื่อง อยู่ด้านซ้ายของถนนช่วงจุดเริ่มต้น
##  มิวแอบปีนกำแพงโรงเรียนออกมาที่นี่ (ถนนช่วงแรกเป็นทางตรงเสมอ จึงวางด้วยพิกัดตรง ๆ ได้)
##  พิกัด: ถนนวิ่งไปทาง -Z, ซ้ายคือ -X, "ด้านหลังจุดเริ่ม" คือ +Z
## =====================================================================

const WALL_X := -6.45            # แนวกำแพงริมทางเท้า
const WALL_H := 2.3
const Z_FAR := 52.0              # ปลายกำแพงด้านหลัง
const Z_NEAR := -30.0            # ปลายกำแพงด้านหน้า
const GATE_Z := 12.0             # กึ่งกลางประตูโรงเรียน
const GATE_W := 5.0
const JUMP_Z := 3.0              # จุดที่มิวปีนกำแพง

const CREAM := Color(0.97, 0.90, 0.74)
const MAROON := Color(0.74, 0.27, 0.27)
const TEAL := Color(0.25, 0.62, 0.66)


func _ready() -> void:
	for c in get_children():
		c.queue_free()
	_yard()
	_wall()
	_gate()
	_building()
	_flag()
	_yard_props()


func _add(n: Node3D) -> Node3D:
	add_child(n)
	return n


func _yard() -> void:
	_add(Props.box(Vector3(40.0, 0.04, Z_FAR - Z_NEAR), Color(0.55, 0.76, 0.40), Vector3(WALL_X - 20.2, 0.01, (Z_FAR + Z_NEAR) * 0.5)))
	# ทางเดินจากประตูไปอาคาร
	_add(Props.box(Vector3(19.0, 0.05, 3.2), Color(0.90, 0.84, 0.72), Vector3(WALL_X - 9.7, 0.03, GATE_Z)))
	# ลานคอนกรีตหน้าอาคาร
	_add(Props.box(Vector3(5.0, 0.05, 40.0), Color(0.80, 0.78, 0.74), Vector3(-22.6, 0.03, 12.0)))


func _wall() -> void:
	var gz0 := GATE_Z - GATE_W * 0.5
	var gz1 := GATE_Z + GATE_W * 0.5
	for seg in [[gz1, Z_FAR], [Z_NEAR, gz0]]:
		var a: float = seg[0]
		var b: float = seg[1]
		var len := b - a
		var zc := (a + b) * 0.5
		_add(Props.box(Vector3(0.32, WALL_H, len), CREAM, Vector3(WALL_X, WALL_H * 0.5, zc)))
		_add(Props.box(Vector3(0.34, 0.45, len), TEAL, Vector3(WALL_X, 0.25, zc)))
		_add(Props.box(Vector3(0.6, 0.14, len), MAROON, Vector3(WALL_X, WALL_H + 0.07, zc)))
		# เสาค้ำกำแพงทุก 6 เมตร
		var z := a + 3.0
		while z < b:
			_add(Props.box(Vector3(0.6, WALL_H + 0.2, 0.5), CREAM.darkened(0.06), Vector3(WALL_X, (WALL_H + 0.2) * 0.5, z)))
			z += 6.0


func _gate() -> void:
	for dz in [-GATE_W * 0.5 - 0.35, GATE_W * 0.5 + 0.35]:
		_add(Props.box(Vector3(0.9, 3.4, 0.7), CREAM.darkened(0.04), Vector3(WALL_X, 1.7, GATE_Z + dz)))
		_add(Props.box(Vector3(1.1, 0.2, 0.9), MAROON, Vector3(WALL_X, 3.5, GATE_Z + dz)))
	# ป้ายชื่อโรงเรียนเหนือประตู
	_add(Props.box(Vector3(0.3, 0.9, GATE_W + 1.8), TEAL, Vector3(WALL_X, 3.65, GATE_Z)))
	for sx in [1.0, -1.0]:
		var lb := Label3D.new()
		lb.text = "โรงเรียนมอดินแดง"
		lb.font = load("res://fonts/Kanit_600SemiBold.ttf") as Font
		lb.font_size = 72
		lb.pixel_size = 0.0068
		lb.modulate = Color(1, 1, 1)
		lb.outline_size = 10
		lb.outline_modulate = Color(0.08, 0.25, 0.28)
		lb.position = Vector3(WALL_X + sx * 0.17, 3.65, GATE_Z)
		lb.rotation_degrees.y = 90.0 * sx
		_add(lb)


func _building() -> void:
	var bx := -31.0
	var bz := 12.0
	var face := bx + 6.0
	_add(Props.box(Vector3(12.0, 9.0, 40.0), Color(0.98, 0.86, 0.55), Vector3(bx, 4.5, bz)))
	_add(Props.box(Vector3(12.6, 0.5, 40.6), MAROON, Vector3(bx, 9.25, bz)))
	_add(Props.box(Vector3(12.2, 0.5, 40.2), MAROON.lightened(0.15), Vector3(bx, 4.6, bz)))
	var z := bz - 17.0
	while z <= bz + 17.1:
		for y in [2.5, 6.8]:
			if y < 3.0 and absf(z - GATE_Z) < 1.6:
				z += 0.0
				continue
			_add(Props.box(Vector3(0.12, 1.6, 2.1), Color(0.55, 0.80, 0.95), Vector3(face + 0.04, y, z)))
			_add(Props.box(Vector3(0.14, 0.08, 2.4), Color(1, 1, 1), Vector3(face + 0.05, y - 0.85, z)))
		z += 3.4
	# ประตูอาคาร + บันได
	_add(Props.box(Vector3(0.2, 2.8, 2.6), Color(0.45, 0.30, 0.20), Vector3(face + 0.05, 1.4, GATE_Z)))
	_add(Props.box(Vector3(1.6, 0.2, 4.0), Color(0.85, 0.82, 0.78), Vector3(face + 0.8, 0.1, GATE_Z)))
	# หอนาฬิกา
	_add(Props.box(Vector3(5.0, 4.5, 5.0), CREAM, Vector3(face - 3.0, 11.5, GATE_Z)))
	_add(Props.box(Vector3(5.6, 0.5, 5.6), MAROON, Vector3(face - 3.0, 13.95, GATE_Z)))
	var clock := Props.cyl(1.2, 0.12, Color(1, 1, 1), Vector3(face - 0.45, 11.7, GATE_Z), 20)
	clock.rotation_degrees.z = 90.0
	_add(clock)
	_add(Props.box(Vector3(0.08, 0.1, 0.9), Color(0.1, 0.1, 0.12), Vector3(face - 0.35, 11.95, GATE_Z - 0.25)))
	_add(Props.box(Vector3(0.08, 0.7, 0.1), Color(0.1, 0.1, 0.12), Vector3(face - 0.35, 11.95, GATE_Z)))


func _flag() -> void:
	var px := -15.0
	var pz := 19.0
	_add(Props.cyl(0.07, 8.0, Color(0.85, 0.85, 0.88), Vector3(px, 4.0, pz), 8))
	_add(Props.ball(0.14, Color(1.0, 0.8, 0.2), Vector3(px, 8.05, pz)))
	var fz := pz + 0.9
	var stripes := [[Color(0.80, 0.15, 0.20), 0.2], [Color(1, 1, 1), 0.2], [Color(0.15, 0.20, 0.55), 0.4], [Color(1, 1, 1), 0.2], [Color(0.80, 0.15, 0.20), 0.2]]
	var y := 7.8
	for st in stripes:
		var h: float = st[1]
		_add(Props.box(Vector3(0.04, h, 1.7), st[0], Vector3(px, y - h * 0.5, fz)))
		y -= h


func _yard_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for p in [Vector3(-11, 0, -8), Vector3(-12, 0, 30), Vector3(-19, 0, 36), Vector3(-17, 0, -14), Vector3(-10, 0, 46), Vector3(-9.5, 0, 22)]:
		var t := Props.tree(rng)
		t.position = p
		_add(t)
	var b := Props.bench(1.8)
	b.position = Vector3(-8.2, 0.0, 28.0)
	b.rotation.y = -PI * 0.5
	_add(b)
	# เพื่อนนักเรียนยืนเล่นในสนาม
	var shirts: Array[Color] = [Color(0.95, 0.95, 0.98), Color(0.9, 0.93, 1.0)]
	for p in [Vector3(-16, 0, 18), Vector3(-17.2, 0, 19.4), Vector3(-12, 0, 33), Vector3(-19, 0, -2), Vector3(-14, 0, -4)]:
		var ped := Props.pedestrian(shirts[rng.randi() % 2])
		ped.position = p
		ped.rotation.y = rng.randf_range(0.0, TAU)
		_add(ped)
