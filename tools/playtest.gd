extends Node
## ตัวทดสอบอัตโนมัติ (ไม่ได้ใช้ตอนเล่นจริง) — ใช้ตรวจสอบเกมระหว่างพัฒนา
##   godot --path . res://tools/playtest.tscn -- mode=shots      บันทึกภาพหน้าจอเนื้อเรื่อง/เกม
##   godot --headless --fixed-fps 60 --path . res://tools/playtest.tscn -- mode=sim runs=5
## "บอท" ขับตัวละครเอง (หลบรถ กระโดด มุด เก็บดาว) เพื่อเช็กว่าด่านผ่านได้จริง

var main: Node
var args := {}
var out_dir := "/tmp/claude-0/-home-claude/eb5cd129-ae76-52da-b984-f0e3ad224657/scratchpad/shots"
var bot_on := false
var bot_collect := true


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().process_frame
	if args.get("mode", "shots") == "sim":
		await _sim()
	elif args.get("mode", "shots") == "curve":
		await _curve()
	elif args.get("mode", "shots") == "bus":
		main.ui.hide_story()
		main.seed_value = 3
		main._start_countdown()
		await _wait(2.5)
		main.start_speed = 4.0
		main._spawn({"kind": "obstacle", "type": "bus", "lane": 0}, main.player.s + 17.0)
		main._spawn({"kind": "obstacle", "type": "walker", "lane": 2}, main.player.s + 12.0)
		await _wait(0.8)
		await _shot("bus_a")
		await _wait(0.6)
		await _shot("bus_b")
	elif args.get("mode", "shots") == "feat":
		await _feat()
	else:
		await _shots()
	get_tree().quit()


func _shot(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("shot ", name)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _shots() -> void:
	var ui = main.ui
	await _wait(1.0)
	await _shot("menu_a")
	for k in 6:
		Records.add_run("ทดสอบ", 120 + k * 85, 3 + k * 4, 150 + k * 140)
	Records.add_run("เพื่อน", 410, 22, 630)
	main.menu._name_edit.text = "ทดสอบ"
	main.menu._open_stats()
	await _wait(0.4)
	await _shot("menu_stats")
	main.menu._stats_root.visible = false
	main.menu._credits_root.visible = true
	await _wait(0.3)
	await _shot("menu_credits")
	main.menu._credits_root.visible = false
	main.menu._on_start()
	await _wait(1.0)
	for i in 6:
		await _wait(0.5)
		ui._on_next() if ui._typing else null      # ให้พิมพ์ข้อความจนครบ
		if i == 2:
			await _wait(1.35)
			await _shot("story_2a")
			await _wait(1.8)
		else:
			await _wait(1.6)
		await _shot("story_%d" % i)
		if i < 5:
			ui._on_next()
	ui._on_next()
	await _wait(0.3)
	await _shot("countdown")
	await _wait(2.4)
	bot_on = true
	await _wait(1.5)
	await _shot("run_a")
	await _wait(2.5)
	await _shot("run_b")
	await _wait(3.0)
	await _shot("run_c")
	await _wait(4.0)
	await _shot("run_d")
	bot_on = false
	main._game_over("hit", "ชนรถยนต์")
	await _wait(2.0)
	await _shot("result")


func _curve() -> void:
	main.ui.hide_story()
	main.seed_value = int(args.get("seed", "11"))
	main.straight_start = 30.0
	main._start_countdown()
	await _wait(2.4)
	bot_on = true
	for k in 8:
		await _wait(2.2)
		await _shot("curve_%d" % k)
		print("s=%.0f yaw=%.2f state=%d" % [main.player.s, main.road.yaw(main.player.s), main.state])


func _feat() -> void:
	main.ui.hide_story()
	main.seed_value = 5
	main._start_countdown()
	await _wait(2.5)
	var pl: Player = main.player
	# ไอเท็มวางข้างหน้า 3 เลน
	for k in 3:
		main._spawn({"kind": "item", "item": ["shield", "magnet", "boost"][k], "lane": k}, pl.s + 14.0)
	await _wait(0.4)
	await _shot("feat_items")
	# กระโดดสองครั้ง
	pl._jump()
	await _wait(0.18)
	pl._jump()
	await _wait(0.2)
	await _shot("feat_flip_a")
	await _wait(0.22)
	await _shot("feat_flip_b")
	await _wait(1.0)
	main._on_item("shield")
	main._on_item("magnet")
	await _wait(0.5)
	await _shot("feat_shield_magnet")
	main._on_item("boost")
	await _wait(0.8)
	await _shot("feat_boost")
	print("stars=", main.stars, " dead=", pl.dead, " state=", main.state)


func _sim() -> void:
	var runs := int(args.get("runs", "5"))
	var max_sec := float(args.get("sec", "90"))
	main.ui.hide_story()
	var results := []
	for r in runs:
		main.seed_value = 1000 + r * 37
		main._start_countdown()
		await _wait(2.4)
		bot_on = true
		bot_collect = args.get("collect", "1") == "1"
		var t0 := Time.get_ticks_msec()
		var sim_t := 0.0
		while main.state == main.State.RUN or main.state == main.State.COUNTDOWN:
			await get_tree().physics_frame
			sim_t += 1.0 / 60.0
			if sim_t > max_sec:
				break
		bot_on = false
		results.append("run %d: state=%s sim=%.1fs dist=%.0fm stars=%d speed=%.1f gap=%.2f" % [r, main.State.keys()[main.state], sim_t, main.distance, main.stars, main.player.speed, main.gap])
		print(results[-1])
		if main.state == main.State.OVER:
			print("   reason: ", main._last_reason, "  lane=", main.player.lane, " y=%.2f sliding=%s" % [main.player.position.y, main.player.sliding])
			for c in main.spawned.get_children():
				if c is Obstacle and absf(c.s - main.player.s) < 12.0:
					print("     near: ", c.type_name, " lane ", c.lane, " dz=%.1f" % (c.s - main.player.s))
		await get_tree().process_frame


# ----------------------------------------------------------------- bot
func _physics_process(_dt: float) -> void:
	if not bot_on or main.state != main.State.RUN:
		return
	var p = main.player
	var speed: float = p.speed
	var lane_threat: Array[float] = [999.0, 999.0, 999.0]      # เวลาที่ BLOCK ที่ใกล้สุดจะถึงตัว (วินาที) ต่อเลน
	var lane_low: Array[float] = [999.0, 999.0, 999.0]
	var lane_high: Array[float] = [999.0, 999.0, 999.0]
	var lane_coin: Array[float] = [999.0, 999.0, 999.0]
	for c in main.spawned.get_children():
		var d: float = c.s - p.s      # + = อยู่ข้างหน้า
		if c is Obstacle:
			var o := c as Obstacle
			var half := 0.5
			match o.type_name:
				"car": half = 2.1
				"bus": half = 4.7
			if d < -half - 1.0 or d > 60.0:
				continue
			var rel := speed + o.move_speed
			var t := maxf(d - half - 0.35, 0.0) / rel
			var lanes := [o.lane] if o.lane >= 0 else [0, 1, 2]
			for l in lanes:
				match o.kind:
					Obstacle.Kind.BLOCK: lane_threat[l] = minf(lane_threat[l], t)
					Obstacle.Kind.LOW: lane_low[l] = minf(lane_low[l], t)
					Obstacle.Kind.HIGH: lane_high[l] = minf(lane_high[l], t)
		elif c is StarCoin and d > 0.0 and d < 40.0:
			for l in 3:
				if absf(c.x_off - Player.LANES[l]) < 0.1:
					lane_coin[l] = minf(lane_coin[l], d)
	var cur: int = p.lane
	var horizon := 1.6
	# เลนที่ปลอดภัย: ไม่มี BLOCK ใน horizon
	var best := cur
	var danger: bool = lane_threat[cur] < horizon
	if danger or (bot_collect and lane_coin[cur] > 900.0):
		var cands := []
		for l in 3:
			if lane_threat[l] >= horizon and absi(l - cur) <= 2:
				cands.append(l)
		# เลือกเลนที่ไม่มีของเตี้ย/สูงด้วยถ้าได้ แล้วเลือกเลนที่มีเหรียญใกล้สุด
		cands.sort_custom(func(a, b):
			var sa: float = (lane_low[a] < 1.0 or lane_high[a] < 1.0) as float * 100.0 + absi(a - cur) * 10.0 + (0.0 if not bot_collect else minf(lane_coin[a], 50.0) * 0.1)
			var sb: float = (lane_low[b] < 1.0 or lane_high[b] < 1.0) as float * 100.0 + absi(b - cur) * 10.0 + (0.0 if not bot_collect else minf(lane_coin[b], 50.0) * 0.1)
			return sa < sb)
		if not cands.is_empty():
			best = cands[0]
	if best != cur and absf(p.lat - Player.LANES[cur]) < 0.5:
		p._change_lane(signi(best - cur))
	cur = p.lane
	# กระโดด / มุด
	if lane_low[cur] < 0.34 and lane_low[cur] > 0.05 and p.is_on_floor() and not p.sliding:
		p._jump()
	if lane_high[cur] < 0.30 and lane_high[cur] > 0.02 and p.is_on_floor() and not p.sliding:
		p._slide()
