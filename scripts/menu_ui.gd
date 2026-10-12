class_name MenuUI
extends CanvasLayer
## =====================================================================
##  หน้าหลักของเกม: ชื่อเกม ปุ่มเริ่ม ช่องชื่อผู้เล่น สถิติ และเครดิต
##  ฉาก 3D ด้านหลังเป็นกล้องหมุนช้า ๆ รอบมิวกับครูวินัยหน้าโรงเรียน (main.gd จัดกล้องให้)
## =====================================================================

signal start_pressed(player_name: String)

const FONT_BODY := preload("res://fonts/Sarabun_400Regular.ttf")
const FONT_BOLD := preload("res://fonts/Sarabun_700Bold.ttf")
const FONT_TITLE := preload("res://fonts/Kanit_600SemiBold.ttf")

const NAVY := Color(0.07, 0.11, 0.21, 0.95)
const NAVY_SOFT := Color(0.13, 0.19, 0.33, 0.95)
const AMBER := Color(1.0, 0.74, 0.22)
const INK := Color(0.96, 0.97, 1.0)
const MUTED := Color(0.74, 0.80, 0.92)
const RED := Color(0.96, 0.36, 0.32)

const MEMBERS := [
	["1", "673380447-2", "พัชราภา อินปากดี", "AI"],
	["2", "673380621-2", "จุฑามาศ ทีหัวช้าง", "AI"],
	["3", "673380629-6", "ธนาดุล หนูสันเทียะ", "AI"],
	["4", "673380627-0", "ธนฤทธิ์ ธรรมวงษา", "AI"],
]

var _root: Control
var _home: Control
var _name_edit: LineEdit
var _stats_root: Control
var _stats_body: VBoxContainer
var _credits_root: Control
var _start_btn: Button


func _ready() -> void:
	layer = 11
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_home()
	_build_stats()
	_build_credits()
	get_viewport().size_changed.connect(_layout)
	_layout()
	visible = false


func open_menu() -> void:
	visible = true
	_stats_root.visible = false
	_credits_root.visible = false
	_home.visible = true
	_name_edit.text = Records.get_name()
	_start_btn.grab_focus()


func close_menu() -> void:
	visible = false


func is_open() -> bool:
	return visible


# ------------------------------------------------------------------ home
func _build_home() -> void:
	_home = Control.new()
	_home.set_anchors_preset(Control.PRESET_FULL_RECT)
	_home.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_home)

	# แถบไล่สีมืดด้านซ้ายและล่าง ช่วยให้ตัวหนังสืออ่านง่ายบนฉาก 3D
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.05, 0.07, 0.16, 0.86), Color(0.05, 0.07, 0.16, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.0, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	shade.texture = gt
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.anchor_right = 0.62
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home.add_child(shade)

	var col := VBoxContainer.new()
	col.name = "Column"
	col.add_theme_constant_override("separation", 12)
	col.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	col.offset_left = 64
	col.offset_right = 600
	col.offset_top = 0
	col.offset_bottom = 0
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	_home.add_child(col)

	var tag := _pill("เกม 3D Endless Runner  ·  Godot", Color(1, 1, 1, 0.14), MUTED, 18)
	col.add_child(tag)

	var title := HBoxContainer.new()
	title.add_theme_constant_override("separation", 18)
	title.rotation = deg_to_rad(-2.5)
	col.add_child(title)
	title.add_child(_outlined("SKIP", 112, Color(1, 1, 1)))
	title.add_child(_outlined("RUN", 112, AMBER))

	var sub := _pill("มิวหนีเรียน!", RED, Color.WHITE, 36)
	col.add_child(sub)

	var tagline := _label("แอบข้ามกำแพงโรงเรียน วิ่งหนีครูวินัยฝ่าเมืองยามเช้า\nเก็บเหรียญดาวความดีให้ได้มากที่สุด", FONT_BODY, 23, INK)
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(tagline)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	col.add_child(gap)

	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", 12)
	col.add_child(nrow)
	nrow.add_child(_label("ชื่อผู้เล่น", FONT_TITLE, 22, AMBER))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "พิมพ์ชื่อของคุณ"
	_name_edit.max_length = 20
	_name_edit.custom_minimum_size = Vector2(260, 46)
	_name_edit.add_theme_font_override("font", FONT_BODY)
	_name_edit.add_theme_font_size_override("font_size", 24)
	_name_edit.add_theme_stylebox_override("normal", _panel(Color(1, 1, 1, 0.14), 14, Color(1, 1, 1, 0.35), 1))
	_name_edit.add_theme_stylebox_override("focus", _panel(Color(1, 1, 1, 0.2), 14, AMBER, 2))
	_name_edit.add_theme_color_override("font_color", INK)
	_name_edit.add_theme_color_override("font_placeholder_color", MUTED)
	_name_edit.add_theme_color_override("caret_color", AMBER)
	_name_edit.text_submitted.connect(func(_t): _on_start())
	nrow.add_child(_name_edit)

	_start_btn = _button("เริ่มเกม", true)
	_start_btn.custom_minimum_size = Vector2(0, 62)
	_start_btn.add_theme_font_size_override("font_size", 32)
	_start_btn.pressed.connect(_on_start)
	col.add_child(_start_btn)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	col.add_child(row2)
	var stats_btn := _button("สถิติของฉัน", false)
	stats_btn.pressed.connect(_open_stats)
	row2.add_child(stats_btn)
	var cred_btn := _button("เครดิต", false)
	cred_btn.pressed.connect(func():
		Audio.play("res://sounds/click.ogg", 1.0, -4.0)
		_credits_root.visible = true)
	row2.add_child(cred_btn)
	var quit_btn := _button("ออกจากเกม", false)
	quit_btn.pressed.connect(func():
		Audio.play("res://sounds/click.ogg", 1.0, -4.0)
		await get_tree().create_timer(0.15).timeout
		get_tree().quit())
	row2.add_child(quit_btn)

	var hint := _label("A / D สลับเลน   W / Space กระโดด   S ก้ม   M เปิด-ปิดเพลง", FONT_BODY, 18, MUTED)
	col.add_child(hint)


func _on_start() -> void:
	var n := Records.clean_name(_name_edit.text)
	Records.set_name(n)
	Audio.play("res://sounds/click.ogg", 1.0, -4.0)
	start_pressed.emit(n)


# ----------------------------------------------------------------- stats
func _modal(parent: Control, width: float) -> Array:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	parent.add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.05, 0.1, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel(NAVY, 26, AMBER, 3))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(width, 0)
	root.add_child(panel)
	var m := MarginContainer.new()
	for k in ["left", "right"]:
		m.add_theme_constant_override("margin_" + k, 34)
	for k in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + k, 26)
	panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)
	return [root, v, panel]


func _build_stats() -> void:
	var parts := _modal(_root, 720)
	_stats_root = parts[0]
	_stats_body = parts[1]


func _open_stats() -> void:
	Audio.play("res://sounds/click.ogg", 1.0, -4.0)
	var n := Records.clean_name(_name_edit.text)
	for c in _stats_body.get_children():
		c.queue_free()
	var v := _stats_body
	v.add_child(_label("สถิติของ  %s" % n, FONT_TITLE, 38, AMBER))

	var sm := Records.summary(n)
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 12)
	v.add_child(tiles)
	_tile(tiles, str(sm["games"]), "รอบที่เล่น")
	_tile(tiles, str(sm["best_score"]), "คะแนนสูงสุด")
	_tile(tiles, "%d ม." % sm["best_dist"], "ไกลที่สุด")
	_tile(tiles, str(sm["total_stars"]), "ดาวสะสม")

	var runs := Records.runs_for(n)
	v.add_child(_label("รอบล่าสุด", FONT_TITLE, 22, INK))
	if runs.is_empty():
		v.add_child(_label("ยังไม่มีสถิติ — ไปวิ่งหนีครูสักรอบก่อนนะ!", FONT_BODY, 22, MUTED))
	else:
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 22)
		grid.add_theme_constant_override("v_separation", 4)
		v.add_child(grid)
		for h in ["รอบ", "วันที่ / เวลา", "ระยะทาง", "ดาว", "คะแนน"]:
			var hl := _label(h, FONT_TITLE, 18, MUTED)
			hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL if h == "วันที่ / เวลา" else 0
			grid.add_child(hl)
		var total := runs.size()
		var best: int = sm["best_score"]
		for i in mini(runs.size(), 10):
			var r: Dictionary = runs[i]
			var is_best := int(r["score"]) == best and best > 0
			var col := AMBER if is_best else INK
			grid.add_child(_label("#%d" % (total - i), FONT_BODY, 20, col))
			var dl := _label(Records.thai_date(int(r["ts"])), FONT_BODY, 20, col)
			dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(dl)
			grid.add_child(_label("%d ม." % int(r["dist"]), FONT_BODY, 20, col))
			grid.add_child(_label(str(int(r["stars"])), FONT_BODY, 20, col))
			grid.add_child(_label(str(int(r["score"])) +    ("  · สูงสุด" if is_best else ""), FONT_BODY, 20, col))

	var lb := Records.leaderboard(5)
	if lb.size() > 1:
		v.add_child(_label("อันดับผู้เล่น (คะแนนสูงสุด)", FONT_TITLE, 22, INK))
		var rank := HBoxContainer.new()
		rank.add_theme_constant_override("separation", 10)
		v.add_child(rank)
		for i in lb.size():
			rank.add_child(_pill("%d. %s  %d" % [i + 1, lb[i]["name"], lb[i]["best"]], Color(1, 1, 1, 0.12), AMBER if i == 0 else INK, 19))

	var close := _button("ปิด", true)
	close.pressed.connect(func():
		Audio.play("res://sounds/click.ogg", 1.0, -4.0)
		_stats_root.visible = false)
	var cr := HBoxContainer.new()
	cr.alignment = BoxContainer.ALIGNMENT_CENTER
	cr.add_child(close)
	v.add_child(cr)
	_stats_root.visible = true
	close.grab_focus()


func _tile(parent: Container, value: String, caption: String) -> void:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.add_theme_stylebox_override("panel", _panel(NAVY_SOFT, 16, Color(1, 1, 1, 0.1), 1))
	parent.add_child(pc)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 8)
	pc.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	m.add_child(v)
	var num := _label(value, FONT_TITLE, 34, AMBER)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(num)
	var cap := _label(caption, FONT_BODY, 17, MUTED)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)


# --------------------------------------------------------------- credits
func _build_credits() -> void:
	var parts := _modal(_root, 700)
	_credits_root = parts[0]
	var v: VBoxContainer = parts[1]
	var t := _label("เครดิต", FONT_TITLE, 40, AMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var g := _label("Skip Run — มิวหนีเรียน", FONT_TITLE, 26, INK)
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(g)
	v.add_child(_label("จัดทำโดย", FONT_TITLE, 22, MUTED))

	for m in MEMBERS:
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", _panel(NAVY_SOFT, 14, Color(1, 1, 1, 0.1), 1))
		v.add_child(pc)
		var mc := MarginContainer.new()
		mc.add_theme_constant_override("margin_left", 16)
		mc.add_theme_constant_override("margin_right", 16)
		mc.add_theme_constant_override("margin_top", 8)
		mc.add_theme_constant_override("margin_bottom", 8)
		pc.add_child(mc)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		mc.add_child(h)
		var num := _label(m[0] + ".", FONT_TITLE, 24, AMBER)
		num.custom_minimum_size = Vector2(30, 0)
		h.add_child(num)
		var id := _label(m[1], FONT_BODY, 22, MUTED)
		id.custom_minimum_size = Vector2(150, 0)
		h.add_child(id)
		var nm := _label(m[2], FONT_BOLD, 24, INK)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nm)
		h.add_child(_pill(m[3], AMBER, Color(0.1, 0.12, 0.2), 18))

	var info := _label("รายวิชา Computer Game Development (CP410844) กลุ่ม 2  ·  มหาวิทยาลัยขอนแก่น", FONT_BODY, 19, MUTED)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(info)
	var assets := _label("โมเดล 3D: Kenney (kenney.nl) CC0 / MIT  ·  แอนิเมชันตัวละคร: Mixamo  ·  ฟอนต์: Sarabun, Kanit (SIL OFL)  ·  เสียงและเพลง: สังเคราะห์ด้วยโค้ด", FONT_BODY, 17, MUTED)
	assets.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(assets)

	var close := _button("ปิด", true)
	close.pressed.connect(func():
		Audio.play("res://sounds/click.ogg", 1.0, -4.0)
		_credits_root.visible = false)
	var cr := HBoxContainer.new()
	cr.alignment = BoxContainer.ALIGNMENT_CENTER
	cr.add_child(close)
	v.add_child(cr)


# ---------------------------------------------------------------- layout
func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	var col := _home.get_node("Column") as Control
	var wide := vs.x / maxf(vs.y, 1.0) >= 1.25
	col.offset_left = 64.0 if wide else 24.0
	col.offset_right = (64.0 + minf(vs.x * 0.5, 560.0)) if wide else (vs.x - 24.0)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _stats_root.visible:
			_stats_root.visible = false
		elif _credits_root.visible:
			_credits_root.visible = false
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- helpers
func _label(t: String, font: Font, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _outlined(t: String, size: int, color: Color) -> Label:
	var l := _label(t, FONT_TITLE, size, color)
	l.add_theme_color_override("font_outline_color", Color(0.10, 0.07, 0.20))
	l.add_theme_constant_override("outline_size", 22)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("shadow_offset_y", 6)
	return l


func _pill(t: String, bg: Color, fg: Color, size: int) -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _panel(bg, 40, Color(0, 0, 0, 0), 0))
	pc.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 3)
	m.add_theme_constant_override("margin_bottom", 3)
	pc.add_child(m)
	m.add_child(_label(t, FONT_TITLE, size, fg))
	return pc


func _panel(bg: Color, radius: int, border: Color, border_w: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.anti_aliasing = true
	return sb


func _button(t: String, primary: bool) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_override("font", FONT_TITLE)
	b.add_theme_font_size_override("font_size", 26 if primary else 21)
	b.custom_minimum_size = Vector2(190 if primary else 0, 54 if primary else 46)
	b.focus_mode = Control.FOCUS_ALL
	var normal := _panel(AMBER if primary else Color(1, 1, 1, 0.12), 16, Color(0, 0, 0, 0) if primary else Color(1, 1, 1, 0.3), 0 if primary else 1)
	var hover := _panel(AMBER.lightened(0.18) if primary else Color(1, 1, 1, 0.22), 16, Color(0, 0, 0, 0) if primary else Color(1, 1, 1, 0.4), 0 if primary else 1)
	var pressed := _panel(AMBER.darkened(0.12) if primary else Color(1, 1, 1, 0.06), 16, Color(0, 0, 0, 0), 0)
	for sb in [normal, hover, pressed]:
		(sb as StyleBoxFlat).content_margin_left = 22
		(sb as StyleBoxFlat).content_margin_right = 22
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", _panel(Color(0, 0, 0, 0), 16, Color(1, 1, 1, 0.9), 3))
	var ink := Color(0.10, 0.12, 0.20) if primary else INK
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, ink)
	return b
