extends Node3D
## =====================================================================
##  Skip Run  —  เกมวิ่ง 3D (Endless Runner)
##  มิวหนีเรียน แล้วโดนครูวินัยไล่
##
##  ลำดับเกม:  เนื้อเรื่อง -> นับถอยหลัง 3-2-1 -> วิ่ง -> จบเกม -> (เล่นอีก / อ่านเรื่องใหม่)
##
##  กติกา
##   - มิววิ่งไปข้างหน้าอัตโนมัติ ความเร็วเพิ่มขึ้นเรื่อย ๆ ตามระยะที่วิ่งได้
##   - สลับ 3 เลน / กระโดด / มุด หลบรถ รถเมล์ คนเดินถนน — ชน = จบเกมทันที
##   - ครูวินัยวิ่งไล่ตามหลัง ระยะห่าง (gap) หดลงเรื่อย ๆ
##     เก็บเหรียญดาวความดีเพื่อดันครูให้ห่างออกไป  ถูกไล่ทัน = จบเกม
## =====================================================================

enum State { STORY, COUNTDOWN, RUN, OVER, MENU }

@export_group("ความเร็ว")
@export var start_speed := 10.0
@export var max_speed := 26.0
@export var speed_gain_per_m := 0.0045         # ความเร็วที่เพิ่มต่อระยะ 1 ม.

@export_group("ครูวินัย")
@export var gap_start := 5.0                   # ระยะห่างตอนเริ่ม (ม.)
@export var gap_max := 6.5
@export var gap_catch := 1.2                   # ถ้าเหลือเท่านี้ = ถูกจับ
@export var closing_base := 0.55               # ครูไล่เข้ามาเร็วเท่าไรต่อวินาที (ที่ความเร็วเริ่มต้น)
@export var closing_per_speed := 0.015
@export var star_push := 0.45                  # เก็บดาว 1 ดวง ดันครูออกไปกี่เมตร

@export_group("ไอเท็ม")
@export var demo_items_first := true           # ไอเท็ม 3 ชิ้นแรกโผล่เร็ว ๆ (เพื่อโชว์) แล้วค่อยกลับเป็นปกติ
@export var item_gap_min := 16.0               # ไอเท็มชิ้นถัดไปโผล่หลังจากชิ้นก่อนอย่างน้อยกี่วินาที
@export var item_gap_max := 26.0
@export var magnet_time := 8.0
@export var magnet_radius := 8.5
@export var boost_time := 3.5
@export var boost_speed_mult := 1.3
@export var boost_gap_gain := 1.2              # ตอนพุ่ง ครูตามหลังห่างขึ้นวินาทีละกี่เมตร

@export_group("ถนน")
@export var curves := true                     # เปิดทางโค้ง (ปิด = ถนนตรงตลอด)
@export var straight_start := 150.0            # ช่วงตรงตอนเริ่มเกมก่อนโค้งแรก (ม.)

@export_group("การสร้างสิ่งกีดขวาง")
@export var first_row_time := 3.4              # แถวแรกไปถึงตัวผู้เล่นกี่วินาทีหลังเริ่ม
@export var spawn_distance := 115.0
@export var seed_value := 0                    # 0 = สุ่มใหม่ทุกครั้ง

const LANES: Array[float] = [-2.2, 0.0, 2.2]

@onready var player: Player = $Player
@onready var teacher: Teacher = $Teacher
@onready var track: Track = $Track
@onready var cam: Camera3D = $Camera
@onready var ui: GameUI = $UI
@onready var ground: StaticBody3D = $Ground
@onready var spawned: Node3D = $Spawned
@onready var env: WorldEnvironment = $WorldEnvironment

var state: State = State.STORY
var rng := RandomNumberGenerator.new()

var stars := 0
var distance := 0.0
var gap := 6.0
var best_score := 0
var player_name := ""
var menu: MenuUI

var _clock := 0.0                              # เวลาที่วิ่งมาแล้ว (วินาที)
var _next_row_t := 0.0
var _plans: Array[Dictionary] = []
var _prev_free: Array = [0, 1, 2]
var _cam_goal := Transform3D.IDENTITY
var _cam_follow := false
var _shake := 0.0
var _count_token := 0
var _last_reason := ""
var _next_item_t := 9.0
var _items_given := 0
var _bell_rung := false
var road := RoadPath.new()
var _magnet_left := 0.0
var _boost_left := 0.0
var _invuln := 0.0
var _whistle_cd := 0.0


# ================================================================ setup
func _ready() -> void:
	RoadPath.active = road
	track.path = road
	player_name = Records.get_name()
	best_score = Records.best_score(player_name)
	menu = MenuUI.new()
	menu.name = "Menu"
	add_child(menu)
	menu.start_pressed.connect(_on_menu_start)
	ui.menu_requested.connect(_back_to_menu)
	ui.story_page_changed.connect(_on_story_page)
	ui.run_requested.connect(_start_countdown)
	ui.retry_requested.connect(_start_countdown)
	ui.story_requested.connect(_back_to_story)
	_reset_world()
	_enter_menu()
	cam.global_transform = _cam_goal


func _reset_world() -> void:
	_story_token += 1
	if _story_tw != null and _story_tw.is_valid():
		_story_tw.kill()
	_say_at(null, "")
	teacher.visible = true
	for c in spawned.get_children():
		c.queue_free()
	_plans.clear()
	var sd := seed_value if seed_value != 0 else (randi() % 100000 + 1)
	road.curves_enabled = curves
	road.straight_start = straight_start
	road.reset(sd)
	track.reset(sd)
	player.reset()
	teacher.reset()
	teacher.follow(0.0, 0.0, gap_start, 0.0, 0.1)
	gap = gap_start
	stars = 0
	distance = 0.0
	_clock = 0.0
	_next_row_t = first_row_time
	_items_given = 0
	_bell_rung = false
	_next_item_t = first_row_time + 1.5 if demo_items_first else 10.0
	_magnet_left = 0.0
	_boost_left = 0.0
	_invuln = 0.0
	_whistle_cd = 0.0
	_prev_free = [0, 1, 2]
	rng.randomize()
	track.update_for(0.0)
	_cam_follow = false


# ============================================================ story flow
const MIW_YARD := Vector3(-10.0, 0.0, 3.0)          # มิวยืนในสนามโรงเรียน (ก่อนปีนกำแพง)
const MIW_OUTSIDE := Vector3(-5.2, 0.12, 3.0)       # ลงมายืนบนทางเท้าอีกฝั่งกำแพง
const TEACHER_GATE := Vector3(-5.4, 0.0, 11.0)      # ครูวินัยโผล่ที่ประตูโรงเรียน

var _story_tw: Tween
var _story_token := 0
var _say3d: Label3D


func _say_at(node: Node3D, text: String, y := 2.45, col := Color(1, 1, 1)) -> void:
	if _say3d == null:
		_say3d = Label3D.new()
		_say3d.font = load("res://fonts/Kanit_600SemiBold.ttf") as Font
		_say3d.font_size = 64
		_say3d.pixel_size = 0.0075
		_say3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_say3d.no_depth_test = true
		_say3d.outline_size = 16
		_say3d.outline_modulate = Color(0.12, 0.1, 0.18)
		add_child(_say3d)
	if _say3d.get_parent() != null:
		_say3d.get_parent().remove_child(_say3d)
	if node == null or text.is_empty():
		_say3d.visible = false
		return
	node.add_child(_say3d)
	_say3d.position = Vector3(0, y, 0)
	_say3d.text = text
	_say3d.modulate = col
	_say3d.visible = true


## ตั้งมิวในฉากเนื้อเรื่อง (ปิดฟิสิกส์ชั่วคราว ขยับเองด้วยโค้ด)
func _story_miw(pos: Vector3, yaw: float, anim := "Idle") -> void:
	player.reset()
	player.frozen = true
	player.position = pos
	player.rotation = Vector3(0.0, yaw, 0.0)
	player.model.play(anim, 0.1, 1.6 if anim == "Run" else 1.0)


func _on_story_page(i: int) -> void:
	if state != State.STORY:
		return
	_story_token += 1
	var token := _story_token
	if _story_tw != null and _story_tw.is_valid():
		_story_tw.kill()
	_say_at(null, "")
	Audio.music_level(-11.0)
	match i:
		0:   # เช้าในโรงเรียน: มองโรงเรียนจากฝั่งถนน มิวยืนอยู่ริมกำแพงในสนาม
			teacher.visible = false
			_story_miw(MIW_YARD, -PI * 0.5)
			_cam_goal = _frame(Vector3(-0.5, 6.2, 10.0), Vector3(-10.0, 1.6, 3.0), 0.24)
		1:   # วางแผน: มองจากด้านหลังมิว เห็นกำแพงและถนนอยู่ตรงหน้า
			teacher.visible = false
			_story_miw(MIW_YARD, -PI * 0.5)
			_say_at(player, "ปีนกำแพงเลยดีกว่า…", 2.3, Color(1.0, 0.92, 0.5))
			_cam_goal = _frame(Vector3(-15.5, 1.9, 6.2), Vector3(-10.0, 1.3, 3.0), 0.24)
		2:   # กระโดดข้ามกำแพง
			teacher.visible = false
			_story_miw(MIW_YARD, -PI * 0.5)
			_cam_goal = _frame(Vector3(1.2, 3.4, 8.5), Vector3(-7.0, 1.7, 3.0), 0.22)
			_story_jump(token)
		3:   # ครูวินัยเห็นที่ประตู
			_story_miw(MIW_OUTSIDE, 0.0)
			teacher.visible = true
			teacher.running = false
			teacher.position = TEACHER_GATE
			teacher.rotation = Vector3(0.0, -0.05, 0.0)
			teacher.model.play("Idle", 0.1)
			_say_at(teacher, "มิว! หยุดนะ!", 2.6, Color(1.0, 0.45, 0.4))
			Audio.play("res://sounds/whistle.ogg", 1.0, -3.0)
			_cam_goal = _frame(Vector3(-1.4, 1.8, 5.2), Vector3(-5.4, 1.3, 11.0), 0.24)
		4:   # ไล่ล่า: มุมข้างเห็นทั้งสองคน มิวนำอยู่ ครูไล่ตามมา
			_story_chase_pose()
			_cam_goal = _frame(Vector3(2.6, 3.0, 10.5), Vector3(0.0, 1.0, 2.6), 0.20)
		_:
			_story_chase_pose()
			_cam_goal = _frame(Vector3(2.6, 3.0, 10.5), Vector3(0.0, 1.0, 2.6), 0.20)


func _story_chase_pose() -> void:
	player.reset()
	teacher.visible = true
	teacher.follow(0.0, 0.0, gap_start, 0.0, 0.1)


func _story_jump(token: int) -> void:
	await get_tree().create_timer(0.9).timeout
	if token != _story_token or state != State.STORY:
		return
	# วิ่งสามก้าวเข้าหากำแพง
	player.model.play("Run", 0.1, 1.8)
	var run_from := player.position
	var run_to := Vector3(-8.0, 0.0, 3.0)
	_story_tw = create_tween()
	_story_tw.tween_property(player, "position", run_to, 0.5)
	await _story_tw.finished
	if token != _story_token or state != State.STORY:
		return
	# กระโดดข้ามกำแพง (โค้งพาราโบลา สูงเกินกำแพง 2.3 ม.)
	player.model.play("Jump", 0.05, 1.0)
	Audio.play("res://sounds/jump.ogg", 0.0, -3.0)
	var a := run_to
	var b := MIW_OUTSIDE
	_story_tw = create_tween()
	_story_tw.tween_method(func(t: float) -> void:
		player.position = Vector3(lerpf(a.x, b.x, t), lerpf(a.y, b.y, t) + 3.4 * 4.0 * t * (1.0 - t), a.z), 0.0, 1.0, 0.95)
	await _story_tw.finished
	if token != _story_token or state != State.STORY:
		return
	Audio.play("res://sounds/land.ogg", 0.0, -7.0)
	player.rotation.y = 0.0
	player.model.play("Idle", 0.1)
	_say_at(player, "เฮ้อ… รอดแล้ว!", 2.3, Color(0.7, 1.0, 0.75))
	_cam_goal = _frame(Vector3(1.2, 2.2, 7.5), Vector3(-5.2, 1.2, 3.0), 0.22)


## หน้าหลัก: มิวกับครูวินัยยืนหน้าโรงเรียน กล้องหมุนช้า ๆ รอบตัว
func _enter_menu() -> void:
	state = State.MENU
	ui.hide_all()
	player.reset()
	teacher.visible = true
	teacher.running = false
	teacher.follow(0.0, 0.0, 5.5, 0.0, 0.1)
	_say_at(null, "")
	Audio.music_level(-11.0)
	menu.open_menu()
	_menu_camera()


func _menu_camera() -> void:
	var t := Time.get_ticks_msec() * 0.001
	var from := Vector3(2.0 + sin(t * 0.30) * 1.3, 1.5 + sin(t * 0.45) * 0.1, -6.2 + cos(t * 0.30) * 0.5)
	_cam_goal = _frame(from, Vector3(0.0, 1.1, 2.9), 0.13)


func _on_menu_start(pname: String) -> void:
	player_name = pname
	best_score = Records.best_score(player_name)
	menu.close_menu()
	state = State.STORY
	ui.show_story(0)
	_on_story_page(0)


func _back_to_menu() -> void:
	_count_token += 1
	_reset_world()
	_enter_menu()


func _back_to_story() -> void:
	_count_token += 1
	_reset_world()
	state = State.STORY
	ui.show_story(0)
	Audio.music_level(-11.0)


# ============================================================= countdown
func _start_countdown() -> void:
	menu.close_menu()
	_count_token += 1
	var token := _count_token
	_reset_world()
	state = State.COUNTDOWN
	ui.show_hud()
	ui.set_hud(0, 0.0, 1.0)
	_cam_follow = true
	_cam_goal = _chase_transform()
	for n in ["3", "2", "1"]:
		ui.show_countdown_text(n, Color(1, 1, 1))
		Audio.play("res://sounds/beep.ogg", 1.0)
		await get_tree().create_timer(0.75).timeout
		if token != _count_token:
			return
	ui.show_countdown_text("วิ่ง!", Color(1.0, 0.8, 0.25))
	Audio.play("res://sounds/go.ogg", 1.0)
	_begin_run()
	await get_tree().create_timer(0.6).timeout
	if token == _count_token:
		ui.hide_countdown()


func _begin_run() -> void:
	state = State.RUN
	Audio.music_level(-8.0)
	player.start_run(start_speed)
	teacher.start_run(start_speed)


# ================================================================= loop
func _physics_process(delta: float) -> void:
	# พื้นเลื่อนตามผู้เล่นเสมอ (ไม่มีรอยต่อให้ CharacterBody สะดุด)
	ground.position = Vector3(player.position.x, 0.0, player.position.z)
	ground.rotation.y = road.yaw(player.s)
	track.update_for(player.s)

	if state == State.RUN:
		_update_run(delta)
	elif state == State.OVER:
		teacher.follow(player.s, player.lat, gap, 0.0, delta)


func _update_run(delta: float) -> void:
	_clock += delta
	distance = player.s
	var speed := clampf(start_speed + distance * speed_gain_per_m, start_speed, max_speed)
	if _boost_left > 0.0:
		speed *= boost_speed_mult
	player.speed = speed
	_tick_powerups(delta)

	# ครูไล่เข้ามา
	if _boost_left > 0.0:
		gap += boost_gap_gain * delta
	else:
		gap -= (closing_base + (speed - start_speed) * closing_per_speed) * delta
	gap = minf(gap, gap_max)
	teacher.follow(player.s, player.lat, gap, speed, delta)
	if gap <= gap_catch:
		_game_over("caught", "")
		return
	_whistle_cd -= delta
	if (gap - gap_catch) / (gap_max - gap_catch) < 0.30 and _whistle_cd <= 0.0:
		Audio.play("res://sounds/whistle.ogg", 1.0, -3.0)
		_whistle_cd = 4.0

	_plan_rows(speed)
	_spawn_due(speed)
	_cleanup()
	var gap_ratio := (gap - gap_catch) / (gap_max - gap_catch)
	teacher.urgency = 1.0 - clampf(gap_ratio, 0.0, 1.0)
	ui.set_hud(stars, distance, gap_ratio)
	_update_clock()
	ui.set_powerups(player.shield, _magnet_left, _boost_left)


# ============================================================== spawning
## เติมแถวสิ่งกีดขวางลงคิว โดยกำหนด "เวลาที่จะไปถึงตัวผู้เล่น" ให้เว้นระยะสม่ำเสมอ
## (คิดเป็นเวลา ไม่ใช่ระยะทาง เพื่อให้สลับเลนทันแม้รถที่วิ่งสวนมามีความเร็วต่างกัน)
func _plan_rows(speed: float) -> void:
	while _next_row_t < _clock + 12.0:
		var spacing := clampf(2.2 - (speed - start_speed) * 0.055, 1.3, 2.2)
		var row := _make_row(_next_row_t)
		# เหรียญดาว: วางครึ่งทางระหว่างแถวก่อนหน้ากับแถวนี้ ในเลนที่แถวนี้โล่ง
		var free_now: Array = row["free"]
		var coin_lane: int = free_now[rng.randi() % free_now.size()]
		if _prev_free.size() > 0:
			var both: Array = free_now.filter(func(l): return _prev_free.has(l))
			if not both.is_empty():
				coin_lane = both[rng.randi() % both.size()]
		var mid_t := _next_row_t - spacing * 0.5
		var dt_c := 1.7 / maxf(speed, 1.0)
		var item_here := _next_row_t >= _next_item_t
		for k in 5:
			if item_here and k == 2:
				var kinds := ["shield", "magnet", "boost"]
				var early := demo_items_first and _items_given < kinds.size()
				var kind: String = kinds[_items_given] if early else kinds[rng.randi() % kinds.size()]
				_plans.append({"kind": "item", "item": kind, "lane": coin_lane, "t": mid_t, "v": 0.0})
				_items_given += 1
				if demo_items_first and _items_given < kinds.size():
					_next_item_t = _next_row_t + rng.randf_range(5.0, 7.0)       # ช่วงต้นเกม: ไอเท็มโผล่ถี่เพื่อโชว์
				else:
					_next_item_t = _next_row_t + rng.randf_range(item_gap_min, item_gap_max)
				continue
			_plans.append({"kind": "coin", "lane": coin_lane, "t": mid_t + (k - 2) * dt_c, "v": 0.0})
		_prev_free = free_now
		_next_row_t += spacing


func _make_row(t: float) -> Dictionary:
	var dist_m := distance + (t - _clock) * start_speed
	var progress := clampf(dist_m / 1200.0, 0.0, 1.0)      # ยิ่งไกล ยิ่งยาก
	var roll := rng.randf()
	var free: Array = [0, 1, 2]
	var items: Array[Dictionary] = []

	if roll < 0.40:
		# ---- รถ / รถเมล์ / คนเดินถนน: ต้องสลับเลน ----
		var blocked := 1 if rng.randf() > progress * 0.8 else 2
		var lanes := [0, 1, 2]
		lanes.shuffle()
		for k in blocked:
			var type := _pick_traffic(progress, blocked)
			items.append({"type": type, "lane": lanes[k]})
			free.erase(lanes[k])
	elif roll < 0.68:
		# ---- สิ่งกีดขวางเตี้ย: กระโดดข้าม ----
		var types := ["cone", "crates", "trash", "bench", "barrier"]
		if rng.randf() < 0.35 + progress * 0.25:
			var t_full: String = ["cone", "barrier"][rng.randi() % 2]
			items.append({"type": t_full, "lane": -1})        # เต็มถนน ต้องกระโดดเท่านั้น
			free = []
		else:
			var lanes := [0, 1, 2]
			lanes.shuffle()
			var n := rng.randi_range(1, 2)
			for k in n:
				items.append({"type": types[rng.randi() % types.size()], "lane": lanes[k]})
				free.erase(lanes[k])
	elif roll < 0.88:
		# ---- สิ่งกีดขวางสูง: ก้มมุด ----
		var t_hi: String = ["sign", "gate"][rng.randi() % 2]
		if rng.randf() < 0.5:
			items.append({"type": t_hi, "lane": -1})
			free = []
		else:
			var lanes := [0, 1, 2]
			lanes.shuffle()
			var n := rng.randi_range(1, 2)
			for k in n:
				items.append({"type": t_hi, "lane": lanes[k]})
				free.erase(lanes[k])
	else:
		# ---- ผสม: เตี้ยหนึ่งเลน + รถอีกเลน + เลนโล่งหนึ่งเลน ----
		var lanes := [0, 1, 2]
		lanes.shuffle()
		items.append({"type": ["cone", "crates", "bench"][rng.randi() % 3], "lane": lanes[0]})
		items.append({"type": _pick_traffic(progress, 2), "lane": lanes[1]})
		free = [lanes[2]]

	for it in items:
		it["kind"] = "obstacle"
		it["t"] = t
		_plans.append(it)
	if free.is_empty():
		free = [0, 1, 2]       # แถวเต็มถนนกระโดด/มุดผ่านได้ — เหรียญวางเลนไหนก็ได้
	return {"free": free}


func _pick_traffic(progress: float, blocked: int) -> String:
	var r := rng.randf()
	if r < 0.22 + progress * 0.10 and blocked == 1:
		return "bus"
	if r < 0.58:
		return "car"
	return "walker"


func _speed_of(type: String) -> float:
	match type:
		"car": return 7.0
		"bus": return 5.0
		"walker": return 1.6
	return 0.0


func _spawn_due(speed: float) -> void:
	var i := 0
	while i < _plans.size():
		var p := _plans[i]
		var v: float = p.get("v", _speed_of(p.get("type", "")))
		var dt: float = p["t"] - _clock
		var dist := (speed + v) * maxf(dt, 0.0)
		if dist <= spawn_distance:
			_spawn(p, player.s + dist)
			_plans.remove_at(i)
		else:
			i += 1


func _spawn(p: Dictionary, at_s: float) -> void:
	if p["kind"] == "coin":
		var coin := StarCoin.create(road.pos(at_s, LANES[p["lane"]]) + Vector3(0, 1.05, 0), at_s)
		coin.x_off = LANES[p["lane"]]
		coin.collected.connect(_on_star)
		spawned.add_child(coin)
	elif p["kind"] == "item":
		var it := PowerUp.create(p["item"], road.pos(at_s, LANES[p["lane"]]) + Vector3(0, 1.1, 0), at_s)
		it.collected.connect(_on_item)
		spawned.add_child(it)
	else:
		var o := Obstacle.create(p["type"], p["lane"], rng)
		o.s = at_s
		o.place()
		o.hit_player.connect(_on_player_hit.bind(o))
		spawned.add_child(o)


func _cleanup() -> void:
	var limit := player.s - 12.0
	for c in spawned.get_children():
		if float(c.get("s")) < limit:
			c.queue_free()
		elif c is Obstacle:
			var o := c as Obstacle
			if not o.honked and (o.type_name == "car" or o.type_name == "bus") and o.s < player.s + 38.0:
				o.honked = true
				if o.lane == player.lane or o.lane == -1:
					Audio.play("res://sounds/horn.ogg", 1.0 if o.type_name == "car" else 0.7, -4.0)


# =============================================================== events
func _on_star() -> void:
	if state != State.RUN:
		return
	stars += 1
	gap = minf(gap + star_push, gap_max)
	Audio.play("res://sounds/coin.ogg", 0.0, -5.0)


func _on_item(kind: String) -> void:
	if state != State.RUN:
		return
	Audio.play("res://sounds/item.ogg", 1.0)
	match kind:
		"shield":
			player.set_effects(true, player.boosting, player.magnet)
			ui.toast("ใบลาป่วย! (ป่วยใจ) กันชนได้ 1 ครั้ง", Color(0.45, 0.78, 1.0))
		"magnet":
			_magnet_left = magnet_time
			player.set_effects(player.shield, player.boosting, true)
			ui.toast("แม่เหล็กดาว! ดาวลอยเข้าหาเอง", Color(1.0, 0.45, 0.65))
		"boost":
			_boost_left = boost_time
			player.set_effects(player.shield, true, player.magnet)
			Audio.play("res://sounds/boost.ogg", 1.0)
			ui.toast("รองเท้าวิ่งเทอร์โบ! พุ่งชนทุกอย่าง", Color(1.0, 0.68, 0.25))


## นาฬิกาเช้า: เริ่ม 07:30 วิ่งไกลขึ้นเวลาก็เดิน ครบ 08:00 ระฆังเข้าเรียนดัง (ประมาณ 1,800 ม.)
func _update_clock() -> void:
	var minutes := 7 * 60 + 30 + int(distance / 60.0)
	ui.set_clock("%02d:%02d น." % [minutes / 60, minutes % 60])
	if minutes >= 8 * 60 and not _bell_rung:
		_bell_rung = true
		ui.toast("08:00 ระฆังเข้าเรียนดังแล้ว! มิวไม่อยู่ในห้อง!", Color(1.0, 0.8, 0.3))
		Audio.play("res://sounds/whistle.ogg", 0.8, -2.0)


func _tick_powerups(delta: float) -> void:
	_invuln = maxf(0.0, _invuln - delta)
	if _boost_left > 0.0:
		_boost_left -= delta
		if _boost_left <= 0.0:
			_boost_left = 0.0
			player.set_effects(player.shield, false, player.magnet)
			_invuln = 0.8                                   # เผื่อเวลาให้ตั้งตัวหลังหมดพุ่ง
	if _magnet_left > 0.0:
		_magnet_left -= delta
		var target := player.position + Vector3(0, 1.0, 0)
		for c in get_tree().get_nodes_in_group("stars"):
			var st := c as Node3D
			var d := st.position.distance_to(target)
			if d < magnet_radius and float(st.get("s")) > player.s - 1.0:
				st.position = st.position.move_toward(target, (14.0 + player.speed) * delta)
		if _magnet_left <= 0.0:
			_magnet_left = 0.0
			player.set_effects(player.shield, player.boosting, false)


func _on_player_hit(reason: String, o: Obstacle) -> void:
	if state != State.RUN:
		return
	if _boost_left > 0.0 or _invuln > 0.0:
		o.smash()
		Audio.play("res://sounds/break.ogg", 0.0, 2.0)
		_shake = maxf(_shake, 0.12)
		return
	if player.shield:
		player.set_effects(false, player.boosting, player.magnet)
		_invuln = 1.2
		o.smash()
		Audio.play("res://sounds/shield_break.ogg", 1.0, 2.0)
		_shake = maxf(_shake, 0.2)
		ui.toast("ใบลาป่วยช่วยไว้!", Color(0.45, 0.78, 1.0))
		return
	_game_over("hit", reason)


func _game_over(kind: String, reason: String) -> void:
	state = State.OVER
	_last_reason = kind + ": " + reason
	var score := stars * 10 + int(distance)
	var prev_best := Records.best_score(player_name)
	var new_best := score > prev_best
	Records.add_run(player_name, int(distance), stars, score)     # บันทึกสถิติรอบนี้
	best_score = maxi(prev_best, score)
	var info := {
		"stars": stars, "distance": distance, "score": score, "best": best_score, "new_best": new_best,
		"player": player_name,
	}
	Audio.music_level(-16.0)
	Audio.play("res://sounds/gameover.ogg", 1.0, 0.0)
	if kind == "caught":
		player.catch_pose()
		teacher.stop()
		_shake = 0.25
		info["title"] = "ครูวินัยจับได้!"
		var lines: Array[String] = [
			"“หนีเรียนอีกแล้วเหรอ มิว! ไปห้องปกครองเดี๋ยวนี้!”  ดาวความดี %d ดวงช่วยหักลบคะแนนความประพฤติได้ %d คะแนน",
			"“ครูเห็นนะ ข้ามรั้วอีกแล้ว!”  ดาวความดี %d ดวงช่วยได้ %d คะแนน (แต่ไม่ช่วยเรื่องหนีเรียน)",
			"ไม้เรียวมาไวกว่ารถเมล์อีกนะ  ดาวความดี %d ดวงช่วยหักลบความประพฤติได้ %d คะแนน",
			"“พรุ่งนี้เข้าเรียนให้ครบทุกคาบนะ!”  ดาวความดี %d ดวงช่วยหักลบความประพฤติได้ %d คะแนน",
		]
		info["flavor"] = lines[randi() % lines.size()] % [stars, stars]
	else:
		player.die(reason)
		Audio.play("res://sounds/crash.ogg", 1.0)
		teacher.stop()
		_shake = 0.45
		info["title"] = "ชนเข้าแล้ว!"
		var quips := {
			"ชนรถเมล์": ["ชนรถเมล์ที่แน่นเอี๊ยด — ไม่มีที่ให้ยืนแล้วจ้ะ", "รถเมล์สาย 8 แน่นกว่านี้ไม่มีอีกแล้ว มิวขอไม่ขึ้นแล้วกัน"],
			"ชนรถยนต์": ["ชนรถยนต์ — ลืมมองก่อนวิ่งอีกแล้วเหรอ", "แตรดังขนาดนั้นยังไม่ยอมหลบอีก"],
			"ชนคนเดินถนน": ["ชนคนเดินถนน — เขาก็แค่ไปซื้อหมูปิ้งนะ", "ขอโทษครับ! รีบหนีครูอยู่"],
			"หัวชนไม้กั้นทางข้าม": ["หัวชนไม้กั้น — ลืมก้มอีกแล้ว", "ไม้กั้นไม่ได้ขึ้นให้ ต้องก้มสิมิว"],
			"หัวชนป้ายร้านค้า": ["หัวชนป้ายร้านค้า — ป้ายแข็งกว่าหัวนะ", "ป้ายร้านไม่หลบให้นะ ต้องก้ม!"],
		}
		var pool: Array = quips.get(reason, ["%s — มิวล้มคว่ำ" % reason])
		info["flavor"] = "%s  (ครูวินัยตามมาทันพอดี)" % pool[randi() % pool.size()]
	await get_tree().create_timer(1.0).timeout
	if state == State.OVER:
		ui.show_result(info)


# ================================================================ camera
func _look(from: Vector3, at: Vector3) -> Transform3D:
	return Transform3D(Basis(), from).looking_at(at, Vector3.UP)


## วางกล้องให้ "subject" ไปอยู่ฝั่งขวาของจอ (frac = สัดส่วนความกว้างจอที่เลื่อน) เพราะหน้าต่างเนื้อเรื่องอยู่ซ้าย
func _frame(from: Vector3, subject: Vector3, frac: float) -> Transform3D:
	var vs := get_viewport().get_visible_rect().size
	if vs.x / maxf(vs.y, 1.0) < 1.25:
		frac = 0.0       # จอแนวตั้ง: หน้าต่างอยู่ด้านล่างแทน ไม่ต้องเลื่อน
	var t := _look(from, subject)
	var dist := from.distance_to(subject)
	var width := 2.0 * dist * tan(deg_to_rad(cam.fov * 0.5)) * (vs.x / maxf(vs.y, 1.0))
	return _look(from, subject - t.basis.x * (frac * width))


func _chase_transform() -> Transform3D:
	var from := road.pos(player.s - 11.0, player.lat * 0.55) + Vector3(0.0, 5.4, 0.0)
	var at := road.pos(player.s + 4.0, player.lat * 0.35) + Vector3(0.0, 0.7, 0.0)
	return _look(from, at)


func _process(delta: float) -> void:
	if state == State.MENU:
		_menu_camera()
	if _cam_follow:
		_cam_goal = _chase_transform()
	var t := cam.global_transform
	var k := 1.0 - exp(-(5.0 if state == State.STORY else 9.0) * delta)
	t.origin = t.origin.lerp(_cam_goal.origin, k)
	t.basis = t.basis.slerp(_cam_goal.basis, k)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 1.2)
		t.origin += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.25
	cam.global_transform = t
	# ภาพกว้างขึ้นเมื่อวิ่งเร็ว
	var target_fov := 60.0 + clampf((player.speed - start_speed) / (max_speed - start_speed), 0.0, 1.0) * 12.0
	cam.fov = lerpf(cam.fov, target_fov, minf(1.0, delta * 3.0))


# ================================================================== save
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_M:
		Audio.toggle_music()
