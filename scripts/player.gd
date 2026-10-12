class_name Player
extends CharacterBody3D
## =====================================================================
##  มิว — ตัวละครที่ผู้เล่นควบคุม
##  ดัดแปลงจาก player.gd ของ Kenney Starter Kit 3D Platformer:
##    เดิม: เดินอิสระทุกทิศ + กระโดด
##    ใหม่: วิ่งไปข้างหน้าอัตโนมัติ (-Z) + สลับ 3 เลน + กระโดด + มุดลอด
##
##  ปุ่ม: ซ้าย/ขวา (A D) สลับเลน | ขึ้น/W/Space กระโดด | ลง/S มุด
##  มือถือ/ทัชสกรีน: ปัดซ้าย ขวา ขึ้น ลง
## =====================================================================

signal landed

const LANES: Array[float] = [-2.2, 0.0, 2.2]

@export_group("การเคลื่อนที่")
@export var lane_speed := 16.0          # ความเร็วสลับเลน (ม./วินาที)
@export var jump_velocity := 8.8
@export var high_jump_velocity := 12.6    # กดกระโดดซ้ำกลางอากาศ = กระโดดสูง (ข้ามรถเก๋งได้)
@export var gravity := 28.0
@export var slide_time := 0.85          # เวลาที่ก้มมุด (วินาที)
@export var stand_height := 1.7
@export var slide_height := 0.95

@onready var model: CharacterModel = $Model
@onready var shape: CollisionShape3D = $CollisionShape3D
@onready var footsteps: AudioStreamPlayer = $Footsteps
@onready var dust: CPUParticles3D = $Dust

var speed := 0.0
var s := 0.0                             # ระยะที่วิ่งไปตามถนน (ม.)
var lat := 0.0                           # ตำแหน่งเยื้องซ้าย-ขวาจากกึ่งกลางถนน
var running := false
var dead := false
var lane := 1
var sliding := false

var _air_jumped := false
var _flip_t := 9.0                       # เวลาตั้งแต่เริ่มตีลังกา (>= FLIP_DUR = ไม่ได้ตีลังกา)
const FLIP_DUR := 0.62
var shield := false
var boosting := false
var magnet := false
var _aura: MeshInstance3D
var _aura_mat: StandardMaterial3D
var _ring: MeshInstance3D
var _fx_t := 0.0

var _slide_left := 0.0
var _slide_queued := false
var _was_on_floor := true
var _touch_start := Vector2.ZERO
var _touching := false


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 8           # ชนเฉพาะพื้น (layer 4)
	_set_height(stand_height)
	if footsteps.stream is AudioStreamOggVorbis:
		(footsteps.stream as AudioStreamOggVorbis).loop = true
	model.rotation.y = PI        # โมเดล Mixamo หันหน้าไป +Z ต้องหมุนให้หันไป -Z
	_build_effects()


func reset() -> void:
	frozen = false
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	lane = 1
	s = 0.0
	lat = 0.0
	speed = 0.0
	running = false
	dead = false
	sliding = false
	_slide_left = 0.0
	_slide_queued = false
	_air_jumped = false
	_flip_t = 9.0
	set_effects(false, false, false)
	model.rotation = Vector3(0.0, PI, 0.0)
	model.position = Vector3.ZERO
	_set_height(stand_height)
	model.play("Idle")


func start_run(start_speed: float) -> void:
	speed = start_speed
	running = true
	dead = false
	model.play("Run", 0.15, 1.6)


func die(_reason := "") -> void:
	if dead:
		return
	dead = true
	running = false
	sliding = false
	velocity.x = 0.0
	footsteps.stream_paused = true
	dust.emitting = false
	Audio.play("res://sounds/fall.ogg")
	model.play("Idle", 0.1)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(model, "rotation:x", -1.3, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(model, "position:y", 0.05, 0.35)


func catch_pose() -> void:
	# ถูกครูจับ — หยุดนิ่งตกใจ
	dead = true
	running = false
	sliding = false
	footsteps.stream_paused = true
	dust.emitting = false
	model.play("Idle", 0.2)


# ------------------------------------------------------------------ input
func _unhandled_input(event: InputEvent) -> void:
	if not running or dead:
		return
	if event.is_action_pressed("move_left"):
		_change_lane(-1)
	elif event.is_action_pressed("move_right"):
		_change_lane(1)
	elif event.is_action_pressed("jump"):
		_jump()
	elif event.is_action_pressed("slide"):
		_slide()
	elif event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touch_start = t.position
			_touching = true
		elif _touching:
			_touching = false
			_swipe(t.position - _touch_start)


func _swipe(d: Vector2) -> void:
	if d.length() < 40.0:
		return
	if absf(d.x) > absf(d.y):
		_change_lane(1 if d.x > 0.0 else -1)
	elif d.y < 0.0:
		_jump()
	else:
		_slide()


func _change_lane(dir: int) -> void:
	var n := clampi(lane + dir, 0, 2)
	if n != lane:
		Audio.play("res://sounds/swish.ogg", 0.0, -6.0)
	lane = n


func _jump() -> void:
	if not is_on_floor() and not _air_jumped:
		# กดซ้ำกลางอากาศ = กระโดดสูง + ตีลังกา
		_air_jumped = true
		velocity.y = high_jump_velocity
		_flip_t = 0.0
		Audio.play("res://sounds/highjump.ogg", 1.0, 0.0)
		model.scale = Vector3(0.85, 1.2, 0.85)
		return
	if is_on_floor():
		if sliding:
			_end_slide()
		_air_jumped = false
		velocity.y = jump_velocity
		Audio.play("res://sounds/jump.ogg", 0.0, -3.0)
		model.play("Jump", 0.05, 1.15, 0.66)
		model.scale = Vector3(0.85, 1.2, 0.85)


func _slide() -> void:
	if not is_on_floor():
		velocity.y = -16.0           # กดลงกลางอากาศ = ดิ่งลงเร็ว แล้วมุดต่อทันที
		_slide_queued = true
		return
	_begin_slide()


func _begin_slide() -> void:
	sliding = true
	_slide_left = slide_time
	_set_height(slide_height)
	model.play("Jump", 0.06, 0.0, 0.5)         # ท่าย่อตัว (เฟรมต่ำสุดของท่า Jump)


func _end_slide() -> void:
	sliding = false
	_slide_left = 0.0
	_set_height(stand_height)
	model.play("Run", 0.1, _run_scale())


func _set_height(h: float) -> void:
	var cap := shape.shape as CapsuleShape3D
	cap.height = h
	shape.position.y = h * 0.5


func _run_scale() -> float:
	return clampf(speed / 6.0, 1.4, 2.5)


# ---------------------------------------------------------------- physics
var frozen := false              # ช่วงเนื้อเรื่อง: main.gd ขยับตัวละครเอง ไม่ใช้ฟิสิกส์


func _physics_process(delta: float) -> void:
	if frozen:
		return
	velocity.y -= gravity * delta

	if running and not dead and RoadPath.active != null:
		# วิ่งไปตามถนน (ตรงหรือโค้งก็ได้): คำนวณตำแหน่งบนถนนแล้วพาตัวละครไปที่นั่น
		var road := RoadPath.active
		s += speed * delta
		lat += clampf((LANES[lane] - lat) * 20.0, -lane_speed, lane_speed) * delta
		var tp := road.pos(s, lat)
		velocity.x = (tp.x - position.x) / delta
		velocity.z = (tp.z - position.z) / delta
		rotation.y = road.yaw(s)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 40.0 * delta)

	move_and_slide()

	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		_air_jumped = false
		_flip_t = 9.0
		model.position = Vector3.ZERO
		Audio.play("res://sounds/land.ogg", 0.0, -7.0)
		model.scale = Vector3(1.2, 0.8, 1.2)
		landed.emit()
		if not sliding and running:
			model.play("Run", 0.08, _run_scale())
		if _slide_queued:
			_slide_queued = false
			_begin_slide()
	_was_on_floor = on_floor

	if sliding:
		_slide_left -= delta
		if _slide_left <= 0.0:
			_end_slide()

	# เอียงตัวตามทิศสลับเลน + คืนรูปทรงหลังกระโดด
	if running and not dead:
		var dx := LANES[lane] - lat
		model.rotation.z = lerpf(model.rotation.z, clampf(dx * 0.12, -0.35, 0.35), minf(1.0, delta * 12.0))
		if on_floor and not sliding:
			model.play("Run", 0.1, _run_scale())
		var tilt := -0.25 if sliding else 0.0
		model.rotation.x = lerpf(model.rotation.x, tilt, minf(1.0, delta * 12.0))
	model.scale = model.scale.lerp(Vector3.ONE, minf(1.0, delta * 10.0))

	# เสียงฝีเท้า + ฝุ่น
	var stepping := running and not dead and on_floor and not sliding
	footsteps.stream_paused = not stepping
	if stepping:
		footsteps.pitch_scale = clampf(speed / 10.0, 0.9, 1.6)
	dust.emitting = stepping and speed > 8.0
	_fx_t += delta
	if _aura != null:
		var pulse := 1.0 + 0.05 * sin(_fx_t * 9.0)
		_aura.scale = Vector3(pulse, pulse, pulse * (1.5 if boosting else 1.0))
		_ring.rotation = Vector3(0.0, _fx_t * 3.0, 0.0)
		_ring.scale = Vector3.ONE * (1.0 + 0.1 * sin(_fx_t * 6.0))


# ---------------------------------------------------------------- effects
func _build_effects() -> void:
	_aura = MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 1.15
	sp.height = 2.3
	_aura.mesh = sp
	_aura.position = Vector3(0, 0.95, 0)
	_aura_mat = StandardMaterial3D.new()
	_aura_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_aura_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_aura_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_aura_mat.albedo_color = Color(0.4, 0.75, 1.0, 0.22)
	_aura.material_override = _aura_mat
	_aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_aura.visible = false
	add_child(_aura)
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.95
	tm.outer_radius = 1.05
	_ring.mesh = tm
	_ring.position = Vector3(0, 0.95, 0)
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(1.0, 0.3, 0.55)
	_ring.material_override = rm
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = false
	add_child(_ring)


func set_effects(sh: bool, bo: bool, mg: bool) -> void:
	shield = sh
	boosting = bo
	magnet = mg
	if _aura == null:
		return
	_aura.visible = sh or bo
	if bo:
		_aura_mat.albedo_color = Color(1.0, 0.6, 0.15, 0.30)
	elif sh:
		_aura_mat.albedo_color = Color(0.4, 0.75, 1.0, 0.22)
	_ring.visible = mg
