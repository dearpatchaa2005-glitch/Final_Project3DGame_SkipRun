class_name Teacher
extends Node3D
## ครูวินัย — วิ่งไล่หลังผู้เล่นตลอดเวลา ระยะห่าง (gap) คือตัวกำหนดจังหวะเกม

@onready var model: CharacterModel = $Model

var running := false
var urgency := 0.0               # 0 = ห่างปลอดภัย, 1 = เกือบทัน (main.gd ตั้งค่าให้) ยิ่งสูงยิ่งตะโกนถี่
var _bob_t := 0.0
var _say: Label3D
var _say_t := 3.0
var _hide_t := 0.0

const CALM_LINES: Array[String] = ["มิว! หยุดก่อน!", "ออกนอกโรงเรียนไม่ได้นะ!", "กลับมาสอบเดี๋ยวนี้!", "ครูเห็นนะ!"]
const ANGRY_LINES: Array[String] = ["หยุดนะ มิว!!", "ตัดคะแนนนะ!!", "อย่าหนี!!", "กลับมาเดี๋ยวนี้!!", "ไม้เรียวมาแล้ว!!"]


func _ready() -> void:
	model.rotation.y = PI
	_say = Label3D.new()
	_say.font = load("res://fonts/Kanit_600SemiBold.ttf") as Font
	_say.font_size = 64
	_say.pixel_size = 0.0075
	_say.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_say.no_depth_test = true
	_say.outline_size = 16
	_say.outline_modulate = Color(0.15, 0.04, 0.04)
	_say.position = Vector3(0, 2.55, 0)
	_say.visible = false
	add_child(_say)


func _process(delta: float) -> void:
	if not running:
		_say.visible = false
		return
	_say_t -= delta
	if _say_t <= 0.0:
		var angry := urgency > 0.55
		var pool := ANGRY_LINES if angry else CALM_LINES
		_say.text = pool[randi() % pool.size()]
		_say.modulate = Color(1.0, 0.35, 0.3) if angry else Color(1.0, 0.92, 0.5)
		_say.visible = true
		_hide_t = 1.5
		_say_t = lerpf(6.5, 2.6, clampf(urgency, 0.0, 1.0)) + randf() * 1.2
	if _hide_t > 0.0:
		_hide_t -= delta
		if _hide_t <= 0.0:
			_say.visible = false


func reset() -> void:
	running = false
	_lat = 0.0
	rotation = Vector3.ZERO
	model.rotation = Vector3(0.0, PI, 0.0)
	model.play("Idle")


func start_run(speed: float) -> void:
	running = true
	model.play("Run", 0.15, clampf(speed / 6.5, 1.3, 2.4))


func stop() -> void:
	running = false
	model.play("Idle", 0.25)


var _lat := 0.0


## ตามผู้เล่น: อยู่หลังผู้เล่น gap เมตรตามแนวถนน และเลื่อนตามเลนแบบหน่วง ๆ
func follow(player_s: float, player_lat: float, gap: float, speed: float, delta: float) -> void:
	_lat = lerpf(_lat, player_lat, 1.0 - exp(-4.5 * delta))
	var road := RoadPath.active
	if road != null:
		position = road.pos(player_s - gap, _lat)
		rotation.y = road.yaw(player_s - gap)
	if running:
		model.play("Run", 0.1, clampf(speed / 6.5, 1.3, 2.4))
		_bob_t += delta
		model.rotation.z = sin(_bob_t * 7.0) * 0.04
