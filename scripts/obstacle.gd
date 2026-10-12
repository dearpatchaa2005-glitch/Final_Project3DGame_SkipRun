@tool
class_name Obstacle
extends Area3D
## =====================================================================
##  สิ่งกีดขวางบนถนน — ชนผู้เล่น = จบเกมทันที
##    LOW   เตี้ย  -> กด "ขึ้น/Space" กระโดดข้าม (กรวย ลังไม้ ถุงขยะ ม้านั่ง แบริเออร์)
##    HIGH  สูง    -> กด "ลง" มุดลอด (ป้ายร้านค้าที่ยื่นออกมา ไม้กั้นทางข้าม)
##    BLOCK ตัน    -> ต้องสลับเลนหลบ (รถยนต์ รถเมล์ คนเดินถนนที่เดินสวนมา)
## =====================================================================

signal hit_player(reason: String)

enum Kind { LOW, HIGH, BLOCK }

var kind: int = Kind.BLOCK
var type_name := ""
var move_speed := 0.0            # เมตร/วินาที ไปทาง +Z (วิ่งสวนผู้เล่น)
var lane := 1                    # 0..2 หรือ -1 = เต็มถนน
var reason := "ชน"
var visual: Node3D
var _bob_phase := 0.0
var _bob := false
var _hit := false
var honked := false
var s := 0.0                     # ตำแหน่งตามแนวถนน (ม.)

const LANES: Array[float] = [-2.2, 0.0, 2.2]


## สร้างสิ่งกีดขวางตามชื่อชนิด (rng ใช้สุ่มสีและป้าย)
static func create(type: String, lane_idx: int, rng: RandomNumberGenerator) -> Obstacle:
	var o := Obstacle.new()
	o.type_name = type
	o.lane = lane_idx
	o._build(rng)
	return o


func _build(rng: RandomNumberGenerator) -> void:
	collision_layer = 2          # layer 2 = obstacle
	collision_mask = 1           # ตรวจจับ layer 1 = player
	monitoring = true
	monitorable = false
	var x := 0.0 if lane < 0 else LANES[lane]
	var width := 7.0 if lane < 0 else 1.9
	position.x = x

	var half := Vector3(0.9, 0.5, 0.4)   # ขนาดครึ่งหนึ่งของกล่องชน
	var center := Vector3(0, 0.5, 0)

	match type_name:
		"cone":
			kind = Kind.LOW
			reason = "สะดุดกรวยจราจร"
			visual = Node3D.new()
			var n := 3 if lane >= 0 else 9
			for i in n:
				var cx := (-0.65 + i * 0.65) if lane >= 0 else (-3.2 + i * 0.8)
				visual.add_child(Props.cone(Vector3(cx, 0, 0)))
			half = Vector3(width * 0.5, 0.35, 0.3)
			center = Vector3(0, 0.35, 0)
		"barrier":
			kind = Kind.LOW
			reason = "ชนแบริเออร์ก่อสร้าง"
			visual = Props.barrier(width)
			half = Vector3(width * 0.5, 0.38, 0.2)
			center = Vector3(0, 0.38, 0)
		"crates":
			kind = Kind.LOW
			reason = "สะดุดลังไม้ของแม่ค้า"
			visual = Props.crates()
			half = Vector3(0.95, 0.38, 0.45)
			center = Vector3(0.1, 0.38, 0)
		"trash":
			kind = Kind.LOW
			reason = "สะดุดถุงขยะ"
			visual = Props.trash_bags()
			half = Vector3(0.85, 0.36, 0.42)
			center = Vector3(0.0, 0.36, 0)
		"bench":
			kind = Kind.LOW
			reason = "ชนม้านั่ง"
			visual = Props.bench(1.8)
			half = Vector3(0.9, 0.42, 0.3)
			center = Vector3(0, 0.42, 0)
		"sign":
			kind = Kind.HIGH
			reason = "หัวชนป้ายร้านค้า"
			var cols: Array[Color] = [Color(0.88, 0.30, 0.28), Color(0.22, 0.52, 0.78), Color(0.95, 0.65, 0.15), Color(0.30, 0.65, 0.40)]
			visual = Props.hanging_sign(width, Props.SIGN_TEXTS[rng.randi() % Props.SIGN_TEXTS.size()], cols[rng.randi() % cols.size()])
			half = Vector3(width * 0.5, 0.4, 0.12)
			center = Vector3(0, 1.85, 0)
		"gate":
			kind = Kind.HIGH
			reason = "หัวชนไม้กั้นทางข้าม"
			visual = Props.crossing_gate(width)
			half = Vector3(width * 0.5, 0.14, 0.1)
			center = Vector3(0, 1.62, 0)
		"car":
			kind = Kind.BLOCK
			reason = "ชนรถยนต์"
			move_speed = 7.0
			visual = Props.external("vehicles", rng, Vector3(1.9, 1.5, 4.2))
			if visual == null:
				visual = Props.car(Props.CAR_COLORS[rng.randi() % Props.CAR_COLORS.size()])
			half = Vector3(0.95, 0.75, 2.1)
			center = Vector3(0, 0.75, 0)
		"bus":
			kind = Kind.BLOCK
			reason = "ชนรถเมล์"
			move_speed = 5.0
			visual = Props.bus()
			half = Vector3(1.25, 1.5, 4.7)
			center = Vector3(0, 1.5, 0)
		"walker":
			kind = Kind.BLOCK
			reason = "ชนคนเดินถนน"
			move_speed = 1.6
			var shirts: Array[Color] = [Color(0.95, 0.75, 0.2), Color(0.3, 0.7, 0.5), Color(0.85, 0.35, 0.55), Color(0.4, 0.5, 0.9)]
			visual = Props.pedestrian(shirts[rng.randi() % shirts.size()])
			if rng.randf() < 0.6:
				var say := Label3D.new()
				say.text = Props.WALKER_SAYS[rng.randi() % Props.WALKER_SAYS.size()]
				say.font = load("res://fonts/Kanit_600SemiBold.ttf") as Font
				say.font_size = 56
				say.pixel_size = 0.0058
				say.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				say.no_depth_test = true
				say.modulate = Color(1, 1, 1)
				say.outline_size = 12
				say.outline_modulate = Color(0.12, 0.1, 0.18)
				say.position = Vector3(0, 2.25, 0)
				visual.add_child(say)
			half = Vector3(0.38, 0.9, 0.25)
			center = Vector3(0, 0.9, 0)
			_bob = true
		_:
			push_warning("ไม่รู้จักชนิดสิ่งกีดขวาง: " + type_name)

	if visual != null:
		add_child(visual)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = half * 2.0
	cs.shape = bs
	cs.position = center
	add_child(cs)
	body_entered.connect(_on_body_entered)
	_bob_phase = rng.randf() * TAU


func _on_body_entered(body: Node3D) -> void:
	if _hit or not body.is_in_group("player"):
		return
	_hit = true
	hit_player.emit(reason)


## ถูกพุ่งชน / โล่ป้องกัน: สิ่งกีดขวางกระเด็นหายไป
func smash() -> void:
	_hit = true
	set_deferred("monitoring", false)
	move_speed = 0.0
	_bob = false
	if visual != null:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(visual, "position", Vector3(randf_range(-2.0, 2.0), 3.5, -3.0), 0.45).as_relative()
		tw.tween_property(visual, "rotation", Vector3(randf_range(-4, 4), randf_range(-4, 4), randf_range(-4, 4)), 0.45)
		tw.tween_property(visual, "scale", Vector3.ONE * 0.2, 0.45)
		tw.chain().tween_callback(queue_free)
	else:
		queue_free()


## วางตามเส้นทางถนนที่ระยะ s (เลน -1 = เต็มถนน อยู่กึ่งกลาง)
func place() -> void:
	var road := RoadPath.active
	if road == null:
		return
	position = road.pos(s, LANES[lane] if lane >= 0 else 0.0)
	rotation.y = road.yaw(s)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if move_speed != 0.0:
		s -= move_speed * delta         # วิ่งสวนเข้ามาหาผู้เล่น (ระยะ s ลดลง)
		place()
	if _bob and visual != null:
		_bob_phase += delta * 9.0
		visual.position.y = absf(sin(_bob_phase)) * 0.07
		visual.rotation.z = sin(_bob_phase) * 0.04
