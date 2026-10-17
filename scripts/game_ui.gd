class_name GameUI
extends CanvasLayer
## =====================================================================
##  หน้าจอทั้งหมดของเกม สร้างด้วยโค้ด (ฟอนต์ไทย Sarabun / Kanit อยู่ใน fonts/)
##    1) หน้าเนื้อเรื่อง (ก่อนเริ่มเกม)  — เล่าเรื่อง + แนะนำตัวละคร + วิธีเล่น
##    2) นับถอยหลัง 3-2-1
##    3) HUD ระหว่างวิ่ง — ดาว ระยะทาง และมิเตอร์ "ครูวินัยตามมา"
##    4) หน้าจบเกม — คะแนนรวม ระยะทาง สถิติสูงสุด
## =====================================================================

signal story_page_changed(index: int)
signal run_requested
signal retry_requested
signal story_requested
signal menu_requested

const FONT_BODY := preload("res://fonts/Sarabun_400Regular.ttf")
const FONT_BOLD := preload("res://fonts/Sarabun_700Bold.ttf")
const FONT_TITLE := preload("res://fonts/Kanit_600SemiBold.ttf")

const NAVY := Color(0.07, 0.11, 0.21, 0.94)
const NAVY_SOFT := Color(0.13, 0.19, 0.33, 0.95)
const AMBER := Color(1.0, 0.74, 0.22)
const INK := Color(0.96, 0.97, 1.0)
const MUTED := Color(0.74, 0.80, 0.92)
const RED := Color(0.96, 0.36, 0.32)
const GREEN := Color(0.42, 0.85, 0.52)

## เนื้อเรื่องตามรายงานออกแบบเกม (แก้ข้อความที่นี่ได้เลย)
const PAGES := [
	{
		"chapter": "ตอนที่ 1  ·  เช้าวันสอบกลางภาค",
		"title": "สายด่วนจากน้อง",
		"text": "เสียงกระดิ่งเข้าห้องสอบดังขึ้น [b]มิว (Miw)[/b] นักเรียนมัธยมปลายกำลังเดินเข้าห้อง โทรศัพท์ในกระเป๋าก็สั่น ปลายสายคือครูโรงเรียนอนุบาล บอกว่าน้องสาวตัวน้อยไข้ขึ้นสูง ต้องมีคนไปรับด่วน มิวโทรหาพ่อแม่ทันที แต่ทั้งคู่ทำงานอยู่ต่างอำเภอ ติดต่อไม่ได้สักคน",
		"card": {"name": "มิว (Miw)", "role": "ตัวเอก นักเรียนมัธยมปลาย ใส่ชุดไม่เรียบร้อย กระเป๋าสะพายหลังโยกไปมา วิ่งเร็วเพราะซ้อมมาทุกเช้า  (ผู้เล่นควบคุม)", "color": Color(0.95, 0.30, 0.26), "initial": "ม"},
	},
	{
		"chapter": "ตอนที่ 2  ·  ขอออกไม่ได้",
		"title": "ไม่มีใบลา ไม่มีทางออก",
		"text": "มิวรีบไปขอครูวินัยให้ออกไปรับน้อง แต่ครูตอบว่า \"วันสอบ ไม่มีข้อยกเว้น ต้องมีใบลาจากผู้ปกครองเท่านั้น\" ลองไปที่ประตูหน้า ยามก็ไม่ให้ออกเหมือนกัน เวลาผ่านไปทุกนาที ทางเดียวที่เหลือคือ [b]กำแพงหลังโรงเรียน[/b] สูงสองเมตรกว่า ๆ มิวหายใจเข้าลึก ๆ ถอยหลังตั้งหลัก…",
		"card": {},
	},
	{
		"chapter": "ตอนที่ 3  ·  ข้ามกำแพง",
		"title": "ขอโทษนะ… แต่ต้องไป!",
		"text": "มิววิ่งสามก้าว กระโดดข้ามกำแพงอย่างสวยงามแล้วลงสู่พื้นฝั่งตรงข้าม ถนนเมืองยามเช้าเปิดโล่งอยู่ตรงหน้า ต้องไปให้ถึงน้องให้เร็วที่สุด!",
		"card": {},
	},
	{
		"chapter": "แต่โชคร้าย…",
		"title": "สายตาเหยี่ยว",
		"text": "แต่โชคร้ายที่ [b]ครูวินัย[/b] ครูฝ่ายปกครองผู้เดินตรวจรอบโรงเรียนระหว่างสอบ มาถึงประตูหลังพอดี และเห็นมิวปีนกำแพงออกไปเต็มสองตา ครูไม่รู้เลยว่ามิวรีบไปทำไม เห็นแค่ว่ามีคนหนีออกจากโรงเรียน",
		"card": {"name": "ครูวินัย (Teacher Winai)", "role": "ครูฝ่ายปกครองผู้เข้มงวด วิ่งไล่ตามผู้เล่นตลอดเวลาอยู่ด้านหลัง เป็นตัวกำหนดจังหวะเกม", "color": Color(0.20, 0.28, 0.52), "initial": "ว"},
	},
	{
		"chapter": "ไล่ล่า!",
		"title": "วิ่งสิ มิว!",
		"text": "ครูวินัยวิ่งไล่ตามทันที มิวจึงต้องวิ่งสุดชีวิตฝ่าเมืองยามเช้าที่พลุกพล่าน หลบหลีกผู้คนและสิ่งกีดขวางต่าง ๆ พร้อมเก็บ [b]เหรียญดาวความดี[/b] ที่หล่นอยู่ตามทาง (ตามตำนานนักเรียนรุ่นพี่ว่าถ้าเก็บครบจะช่วยหักลบคะแนนความประพฤติตอนโดนจับได้) ให้ได้มากที่สุด มิวต้องไปให้ถึงน้องให้ทัน ก่อนที่ครูวินัยจะไล่ทัน",
		"card": {},
	},
	{
		"chapter": "วิธีเล่น",
		"title": "ก่อนออกวิ่ง",
		"text": "",
		"card": {},
		"controls": true,
	},
]

const CONTROLS := [
	["A / D", "สลับ 3 เลนบนถนน (ใช้ลูกศรซ้าย-ขวาก็ได้)"],
	["W / Space", "กระโดดข้ามของเตี้ย เช่น กรวย ลังไม้ ถุงขยะ แบริเออร์ (ลูกศรขึ้นก็ได้)"],
	["กดกระโดดซ้ำ", "กดอีกครั้งกลางอากาศ = กระโดดสูง ตีลังกาข้ามรถเก๋งได้"],
	["S", "ก้มมุดลอดของสูง เช่น ป้ายร้านค้า ไม้กั้นทางข้าม (ลูกศรลงก็ได้)"],
	["หลบให้พ้น", "รถยนต์ รถเมล์ และคนเดินถนนที่สวนมา — ชน = จบเกมทันที"],
	["เก็บดาว", "เหรียญดาวความดีช่วยดันครูวินัยให้ห่างออกไป"],
	["ไอเท็ม", "ใบลาป่วย = กันชน 1 ครั้ง | แม่เหล็ก = ดูดดาว | รองเท้าวิ่ง = พุ่งทะลุทุกอย่าง"],
	["M", "เปิด/ปิดเพลง"],
	["มือถือ", "ปัดนิ้วซ้าย ขวา ขึ้น ลง บนหน้าจอ"],
]

# ------------------------------------------------------------------ nodes
var _story_root: Control
var _story_panel: PanelContainer
var _chapter: Label
var _page_no: Label
var _title: Label
var _text: RichTextLabel
var _card: PanelContainer
var _card_badge: Label
var _card_badge_panel: PanelContainer
var _card_name: Label
var _card_role: Label
var _controls_box: VBoxContainer
var _skip_btn: Button
var _next_btn: Button

var _hud_root: Control
var _pu_chips: Dictionary = {}
var _pu_labels: Dictionary = {}
var _toast_label: Label
var _toast_tween: Tween
var _stars_label: Label
var _dist_label: Label
var _time_label: Label
var _gap_bar: ProgressBar
var _gap_fill: StyleBoxFlat
var _warn_label: Label
var _center_label: Label

var _result_root: Control
var _result_panel: PanelContainer
var _res_title: Label
var _res_flavor: Label
var _res_stars: Label
var _res_dist: Label
var _res_score: Label
var _res_best: Label
var _res_new: Label
var _retry_btn: Button
var _story_btn: Button

var _page := 0
var _type_tween: Tween
var _typing := false
var _warn_t := 0.0


func _ready() -> void:
	layer = 10
	_build_story()
	_build_hud()
	_build_result()
	get_viewport().size_changed.connect(_layout)
	_layout()
	hide_all()


# ======================================================== public interface
func hide_all() -> void:
	_story_root.visible = false
	_hud_root.visible = false
	_result_root.visible = false
	_center_label.visible = false


func show_story(page := 0) -> void:
	_hud_root.visible = false
	_result_root.visible = false
	_center_label.visible = false
	_story_root.visible = true
	_show_page(page)


func hide_story() -> void:
	_story_root.visible = false


func show_hud() -> void:
	set_powerups(false, 0.0, 0.0)
	if _toast_label != null:
		_toast_label.modulate.a = 0.0
	_story_root.visible = false
	_result_root.visible = false
	_hud_root.visible = true
	_warn_label.visible = false


func set_hud(stars: int, distance_m: float, gap_ratio: float) -> void:
	_stars_label.text = str(stars)
	_dist_label.text = "%d ม." % int(distance_m)
	var r := clampf(gap_ratio, 0.0, 1.0)
	_gap_bar.value = r * 100.0
	var col := RED.lerp(AMBER, clampf(r * 2.0, 0.0, 1.0)) if r < 0.5 else AMBER.lerp(GREEN, (r - 0.5) * 2.0)
	_gap_fill.bg_color = col
	_warn_label.visible = r < 0.30 and _hud_root.visible
	if _warn_label.visible:
		_warn_t += get_process_delta_time()
		_warn_label.modulate.a = 0.55 + 0.45 * sin(_warn_t * 14.0)


func show_countdown_text(t: String, color := Color.WHITE) -> void:
	_center_label.text = t
	_center_label.modulate = color
	_center_label.visible = true
	_center_label.pivot_offset = _center_label.size * 0.5
	_center_label.scale = Vector2(1.5, 1.5)
	var tw := create_tween()
	tw.tween_property(_center_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_countdown() -> void:
	_center_label.visible = false


func show_result(info: Dictionary) -> void:
	_hud_root.visible = false
	_center_label.visible = false
	_res_title.text = info.get("title", "")
	_res_title.add_theme_color_override("font_color", info.get("title_color", RED))
	_res_flavor.text = info.get("flavor", "")
	_res_stars.text = str(info.get("stars", 0))
	_res_dist.text = "%d ม." % int(info.get("distance", 0))
	_res_score.text = str(info.get("score", 0))
	_res_best.text = "%s  ·  สถิติสูงสุด %d" % [info.get("player", ""), int(info.get("best", 0))]
	_res_new.visible = bool(info.get("new_best", false))
	_result_root.visible = true
	_result_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_result_panel, "modulate:a", 1.0, 0.3)
	_retry_btn.grab_focus()


func is_result_visible() -> bool:
	return _result_root.visible


# ============================================================== story UI
func _build_story() -> void:
	_story_root = Control.new()
	_story_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_story_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_story_root)

	_story_panel = PanelContainer.new()
	_story_panel.add_theme_stylebox_override("panel", _panel_style(NAVY, 24, AMBER, 3))
	_story_panel.anchor_left = 0.5
	_story_panel.anchor_right = 0.5
	_story_panel.anchor_top = 1.0
	_story_panel.anchor_bottom = 1.0
	_story_panel.offset_bottom = -26.0
	_story_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_story_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_story_root.add_child(_story_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	_story_panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	_chapter = _label("", FONT_TITLE, 22, AMBER)
	_chapter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_chapter)
	_page_no = _label("", FONT_BODY, 20, MUTED)
	head.add_child(_page_no)

	_title = _label("", FONT_TITLE, 40, INK)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_title)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_override("normal_font", FONT_BODY)
	_text.add_theme_font_override("bold_font", FONT_BOLD)
	_text.add_theme_font_size_override("normal_font_size", 24)
	_text.add_theme_font_size_override("bold_font_size", 24)
	_text.add_theme_color_override("default_color", INK)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_text)

	# การ์ดแนะนำตัวละคร
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", _panel_style(NAVY_SOFT, 16, Color(1, 1, 1, 0.10), 1))
	v.add_child(_card)
	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 16)
	cm.add_theme_constant_override("margin_right", 16)
	cm.add_theme_constant_override("margin_top", 12)
	cm.add_theme_constant_override("margin_bottom", 12)
	_card.add_child(cm)
	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 16)
	cm.add_child(ch)
	_card_badge_panel = PanelContainer.new()
	_card_badge_panel.custom_minimum_size = Vector2(64, 64)
	ch.add_child(_card_badge_panel)
	_card_badge = _label("", FONT_TITLE, 34, Color.WHITE)
	_card_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card_badge_panel.add_child(_card_badge)
	var cv := VBoxContainer.new()
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.add_theme_constant_override("separation", 2)
	ch.add_child(cv)
	_card_name = _label("", FONT_TITLE, 26, AMBER)
	cv.add_child(_card_name)
	_card_role = _label("", FONT_BODY, 21, MUTED)
	_card_role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cv.add_child(_card_role)

	# วิธีเล่น
	_controls_box = VBoxContainer.new()
	_controls_box.add_theme_constant_override("separation", 8)
	v.add_child(_controls_box)
	for row in CONTROLS:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		_controls_box.add_child(h)
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", _panel_style(Color(1, 1, 1, 0.12), 10, Color(1, 1, 1, 0.25), 1))
		chip.custom_minimum_size = Vector2(150, 0)
		h.add_child(chip)
		var chip_l := _label(row[0], FONT_TITLE, 20, AMBER)
		chip_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.add_child(chip_l)
		var d := _label(row[1], FONT_BODY, 20, INK)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(d)

	# ปุ่ม
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 12)
	v.add_child(btns)
	_skip_btn = _button("ข้ามไปเริ่มเกม", false)
	_skip_btn.pressed.connect(_on_skip)
	btns.add_child(_skip_btn)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(sp)
	_next_btn = _button("ถัดไป", true)
	_next_btn.pressed.connect(_on_next)
	btns.add_child(_next_btn)


func _show_page(i: int) -> void:
	_page = clampi(i, 0, PAGES.size() - 1)
	var p: Dictionary = PAGES[_page]
	_chapter.text = p["chapter"]
	_page_no.text = "%d / %d" % [_page + 1, PAGES.size()]
	_title.text = p["title"]
	_text.text = p["text"]
	_text.visible = not String(p["text"]).is_empty()
	var card: Dictionary = p["card"]
	_card.visible = not card.is_empty()
	if not card.is_empty():
		_card_name.text = card["name"]
		_card_role.text = card["role"]
		_card_badge.text = card["initial"]
		_card_badge_panel.add_theme_stylebox_override("panel", _panel_style(card["color"], 32, Color(1, 1, 1, 0.5), 2))
	_controls_box.visible = p.get("controls", false)
	var last := _page == PAGES.size() - 1
	_next_btn.text = "ออกวิ่ง!" if last else "ถัดไป"
	_skip_btn.visible = not last
	story_page_changed.emit(_page)
	_start_typing()
	_next_btn.grab_focus()


func _start_typing() -> void:
	if _type_tween != null:
		_type_tween.kill()
	if not _text.visible:
		_typing = false
		return
	_text.visible_ratio = 0.0
	_typing = true
	var n := maxi(1, _text.get_total_character_count())
	_type_tween = create_tween()
	_type_tween.tween_property(_text, "visible_ratio", 1.0, clampf(n * 0.028, 0.6, 5.0))
	_type_tween.finished.connect(func(): _typing = false)


func _on_next() -> void:
	Audio.play("res://sounds/click.ogg", 1.0, -4.0)
	if _typing:
		if _type_tween != null:
			_type_tween.kill()
		_text.visible_ratio = 1.0
		_typing = false
		return
	if _page < PAGES.size() - 1:
		_show_page(_page + 1)
	else:
		_story_root.visible = false
		run_requested.emit()


func _on_skip() -> void:
	Audio.play("res://sounds/click.ogg", 1.0, -4.0)
	_story_root.visible = false
	run_requested.emit()


# ================================================================== HUD
func _build_hud() -> void:
	_hud_root = Control.new()
	_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.visible = false
	add_child(_hud_root)

	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 22
	top.offset_right = -22
	top.offset_top = 18
	top.add_theme_constant_override("separation", 14)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.add_child(top)

	# ดาว
	var sc := _chip()
	top.add_child(sc)
	var sh := HBoxContainer.new()
	sh.add_theme_constant_override("separation", 10)
	sc.get_child(0).add_child(sh)
	var star := StarIcon.new()
	star.custom_minimum_size = Vector2(36, 36)
	sh.add_child(star)
	_stars_label = _label("0", FONT_TITLE, 34, AMBER)
	_stars_label.custom_minimum_size = Vector2(54, 0)
	sh.add_child(_stars_label)

	# ระยะทาง
	var dc := _chip()
	top.add_child(dc)
	_dist_label = _label("0 ม.", FONT_TITLE, 34, INK)
	dc.get_child(0).add_child(_dist_label)

	# นาฬิกาเช้า (ตลก ๆ ใกล้เข้าแถว)
	var tc := _chip()
	top.add_child(tc)
	_time_label = _label("07:30 น.", FONT_TITLE, 28, Color(1.0, 0.82, 0.4))
	tc.get_child(0).add_child(_time_label)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(sp)

	# มิเตอร์ครูวินัย
	var gc := _chip()
	top.add_child(gc)
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 4)
	gc.get_child(0).add_child(gv)
	gv.add_child(_label("ครูวินัยตามมา", FONT_TITLE, 20, MUTED))
	_gap_bar = ProgressBar.new()
	_gap_bar.custom_minimum_size = Vector2(240, 20)
	_gap_bar.show_percentage = false
	_gap_bar.max_value = 100.0
	_gap_bar.value = 100.0
	var bg := _panel_style(Color(1, 1, 1, 0.16), 10, Color(0, 0, 0, 0), 0)
	_gap_fill = _panel_style(GREEN, 10, Color(0, 0, 0, 0), 0)
	_gap_bar.add_theme_stylebox_override("background", bg)
	_gap_bar.add_theme_stylebox_override("fill", _gap_fill)
	gv.add_child(_gap_bar)

	_warn_label = _label("ครูวินัยใกล้แล้ว! เก็บดาวเร็ว!", FONT_TITLE, 34, RED)
	_warn_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_warn_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_warn_label.offset_top = 96
	_warn_label.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.14))
	_warn_label.add_theme_constant_override("outline_size", 10)
	_warn_label.visible = false
	_hud_root.add_child(_warn_label)

	_build_powerups()

	# ตัวเลขนับถอยหลังกลางจอ
	_center_label = _label("", FONT_TITLE, 160, Color.WHITE)
	_center_label.set_anchors_preset(Control.PRESET_CENTER)
	_center_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_center_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.add_theme_color_override("font_outline_color", Color(0.07, 0.11, 0.21))
	_center_label.add_theme_constant_override("outline_size", 24)
	_center_label.visible = false
	add_child(_center_label)


func _build_powerups() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_TOP_LEFT)
	row.offset_left = 22
	row.offset_top = 100
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.add_child(row)
	var defs := {
		"shield": ["ใบลาป่วย", Color(0.45, 0.78, 1.0)],
		"magnet": ["แม่เหล็ก", Color(1.0, 0.45, 0.65)],
		"boost": ["รองเท้าวิ่ง", Color(1.0, 0.68, 0.25)],
	}
	for k in defs.keys():
		var chip := _chip()
		chip.visible = false
		row.add_child(chip)
		var lb := _label(defs[k][0], FONT_TITLE, 22, defs[k][1])
		chip.get_child(0).add_child(lb)
		_pu_chips[k] = chip
		_pu_labels[k] = lb
	_toast_label = _label("", FONT_TITLE, 30, Color.WHITE)
	_toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_label.offset_top = 150
	_toast_label.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.14))
	_toast_label.add_theme_constant_override("outline_size", 10)
	_toast_label.modulate.a = 0.0
	_hud_root.add_child(_toast_label)


func set_clock(t: String) -> void:
	_time_label.text = t


## แสดงสถานะไอเท็มที่ใช้อยู่ (เวลาเหลือเป็นวินาที)
func set_powerups(shield: bool, magnet_left: float, boost_left: float) -> void:
	_pu_chips["shield"].visible = shield
	_pu_chips["magnet"].visible = magnet_left > 0.0
	_pu_chips["boost"].visible = boost_left > 0.0
	_pu_labels["magnet"].text = "แม่เหล็ก %.1f" % magnet_left
	_pu_labels["boost"].text = "รองเท้าวิ่ง %.1f" % boost_left


func toast(text: String, color := Color.WHITE) -> void:
	_toast_label.text = text
	_toast_label.add_theme_color_override("font_color", color)
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_label.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.2)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.5)


func _chip() -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _panel_style(NAVY, 18, Color(1, 1, 1, 0.12), 1))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 8)
	pc.add_child(m)
	return pc


# =============================================================== result
func _build_result() -> void:
	_result_root = Control.new()
	_result_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_root.visible = false
	add_child(_result_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.05, 0.1, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_root.add_child(dim)

	_result_panel = PanelContainer.new()
	_result_panel.add_theme_stylebox_override("panel", _panel_style(NAVY, 26, AMBER, 3))
	_result_panel.set_anchors_preset(Control.PRESET_CENTER)
	_result_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_result_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_result_panel.custom_minimum_size = Vector2(620, 0)
	_result_root.add_child(_result_panel)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 36)
	m.add_theme_constant_override("margin_right", 36)
	m.add_theme_constant_override("margin_top", 28)
	m.add_theme_constant_override("margin_bottom", 28)
	_result_panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	_res_title = _label("", FONT_TITLE, 56, RED)
	_res_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_res_title)
	_res_flavor = _label("", FONT_BODY, 24, MUTED)
	_res_flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_res_flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_res_flavor)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 14)
	v.add_child(stats)
	_res_stars = _stat(stats, "ดาวความดี")
	_res_dist = _stat(stats, "ระยะทาง")
	_res_score = _stat(stats, "คะแนนรวม")

	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_theme_constant_override("separation", 14)
	v.add_child(bh)
	_res_best = _label("", FONT_BODY, 22, INK)
	bh.add_child(_res_best)
	_res_new = _label("สถิติใหม่!", FONT_TITLE, 22, AMBER)
	_res_new.visible = false
	bh.add_child(_res_new)

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 14)
	v.add_child(btns)
	_story_btn = _button("อ่านเนื้อเรื่องอีกครั้ง", false)
	_story_btn.pressed.connect(func(): story_requested.emit())
	btns.add_child(_story_btn)
	var menu_btn := _button("หน้าหลัก", false)
	menu_btn.pressed.connect(func(): menu_requested.emit())
	btns.add_child(menu_btn)
	_retry_btn = _button("เล่นอีกครั้ง", true)
	_retry_btn.pressed.connect(func(): retry_requested.emit())
	btns.add_child(_retry_btn)


func _stat(parent: Container, caption: String) -> Label:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.add_theme_stylebox_override("panel", _panel_style(NAVY_SOFT, 16, Color(1, 1, 1, 0.1), 1))
	parent.add_child(pc)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	pc.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	m.add_child(v)
	var num := _label("0", FONT_TITLE, 44, AMBER)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(num)
	var cap := _label(caption, FONT_BODY, 19, MUTED)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)
	return num


# ============================================================== helpers
func _unhandled_input(event: InputEvent) -> void:
	if _story_root.visible and event.is_action_pressed("ui_accept") and not event.is_echo():
		_on_next()
		get_viewport().set_input_as_handled()
	elif _result_root.visible and event.is_action_pressed("ui_accept") and not event.is_echo():
		retry_requested.emit()
		get_viewport().set_input_as_handled()


## จอกว้าง: หน้าต่างเนื้อเรื่องอยู่ซ้าย ตัวละคร 3D อยู่ขวา | จอแคบ/แนวตั้ง: หน้าต่างอยู่ด้านล่าง
func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	var wide := vs.x / maxf(vs.y, 1.0) >= 1.25
	if wide:
		var w := clampf(vs.x * 0.47, 420.0, 660.0)
		_story_panel.anchor_left = 0.0
		_story_panel.anchor_right = 0.0
		_story_panel.anchor_top = 0.5
		_story_panel.anchor_bottom = 0.5
		_story_panel.offset_left = 28.0
		_story_panel.offset_right = 28.0 + w
		_story_panel.offset_top = 0.0
		_story_panel.offset_bottom = 0.0
		_story_panel.grow_horizontal = Control.GROW_DIRECTION_END
		_story_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
		_story_panel.custom_minimum_size.x = w
	else:
		var sw := clampf(vs.x - 32.0, 280.0, 940.0)
		_story_panel.anchor_left = 0.5
		_story_panel.anchor_right = 0.5
		_story_panel.anchor_top = 1.0
		_story_panel.anchor_bottom = 1.0
		_story_panel.offset_left = -sw * 0.5
		_story_panel.offset_right = sw * 0.5
		_story_panel.offset_top = 0.0
		_story_panel.offset_bottom = -16.0
		_story_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_story_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_story_panel.custom_minimum_size.x = sw
	_result_panel.custom_minimum_size.x = clampf(vs.x - 32.0, 280.0, 620.0)


func _label(t: String, font: Font, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _panel_style(bg: Color, radius: int, border: Color, border_w: int) -> StyleBoxFlat:
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
	var normal := _panel_style(AMBER if primary else Color(1, 1, 1, 0.10), 16, Color(0, 0, 0, 0) if primary else Color(1, 1, 1, 0.3), 0 if primary else 1)
	var hover := _panel_style(AMBER.lightened(0.18) if primary else Color(1, 1, 1, 0.20), 16, Color(0, 0, 0, 0) if primary else Color(1, 1, 1, 0.4), 0 if primary else 1)
	var pressed := _panel_style(AMBER.darkened(0.12) if primary else Color(1, 1, 1, 0.06), 16, Color(0, 0, 0, 0), 0)
	for sb in [normal, hover, pressed]:
		(sb as StyleBoxFlat).content_margin_left = 22
		(sb as StyleBoxFlat).content_margin_right = 22
	var focus := _panel_style(Color(0, 0, 0, 0), 16, Color(1, 1, 1, 0.9), 3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", focus)
	var ink := Color(0.10, 0.12, 0.20) if primary else INK
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)
	b.add_theme_color_override("font_focus_color", ink)
	return b


## ไอคอนดาว วาดด้วยโค้ด (ฟอนต์ไม่ต้องมีสัญลักษณ์ ★)
class StarIcon extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		var pts := PackedVector2Array()
		for i in 10:
			var a := -PI * 0.5 + i * PI / 5.0
			var rr := r if i % 2 == 0 else r * 0.45
			pts.append(c + Vector2(cos(a), sin(a)) * rr)
		draw_colored_polygon(pts, Color(1.0, 0.80, 0.15))
		pts.append(pts[0])
		draw_polyline(pts, Color(0.75, 0.50, 0.05), 2.0, true)
