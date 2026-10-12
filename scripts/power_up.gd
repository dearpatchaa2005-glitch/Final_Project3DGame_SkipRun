@tool
class_name PowerUp
extends Area3D
## ไอเท็มพิเศษที่ลอยอยู่บนถนน — วิ่งชนเพื่อเก็บ
##   shield  "ใบลาป่วย"      กันการชนได้ 1 ครั้ง
##   magnet  "แม่เหล็กดาว"   ดูดดาวรอบตัวเป็นเวลา magnet_time วินาที
##   boost   "รองเท้าวิ่ง"   พุ่งเร็วและทะลุสิ่งกีดขวางชั่วคราว + ดันครูให้ห่าง

signal collected(kind: String)

const INFO := {
	"shield": {"label": "ใบลาป่วย", "color": Color(0.35, 0.72, 1.0)},
	"magnet": {"label": "แม่เหล็กดาว", "color": Color(1.0, 0.3, 0.55)},
	"boost": {"label": "รองเท้าวิ่ง", "color": Color(1.0, 0.6, 0.15)},
}

var kind := "shield"
var _t := 0.0
var _taken := false
var s := 0.0                     # ตำแหน่งตามแนวถนน (ม.)
var _icon: Node3D


static func create(k: String, pos: Vector3, s_pos := 0.0) -> PowerUp:
	var p := PowerUp.new()
	p.kind = k
	p.position = pos
	p.s = s_pos
	p._build()
	return p


func _build() -> void:
	collision_layer = 4
	collision_mask = 1
	monitoring = true
	monitorable = false
	var col: Color = INFO[kind]["color"]
	# ฐานเรืองแสงเป็นวงกลม
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.62
	cm.bottom_radius = 0.62
	cm.height = 0.06
	disc.mesh = cm
	disc.material_override = Props.glow_mat(col, 1.2)
	disc.position.y = -0.55
	add_child(disc)
	# ไอคอน 3D ตามชนิด
	_icon = Node3D.new()
	add_child(_icon)
	match kind:
		"shield":
			var paper := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.55, 0.72, 0.06)
			paper.mesh = bm
			paper.material_override = Props.mat(Color(0.97, 0.97, 0.95))
			_icon.add_child(paper)
			var cross_h := MeshInstance3D.new()
			var hb := BoxMesh.new()
			hb.size = Vector3(0.34, 0.10, 0.08)
			cross_h.mesh = hb
			cross_h.material_override = Props.glow_mat(Color(0.9, 0.2, 0.25), 0.5)
			_icon.add_child(cross_h)
			var cross_v := MeshInstance3D.new()
			var vb := BoxMesh.new()
			vb.size = Vector3(0.10, 0.34, 0.08)
			cross_v.mesh = vb
			cross_v.material_override = cross_h.material_override
			_icon.add_child(cross_v)
		"magnet":
			var red := Props.glow_mat(Color(0.92, 0.18, 0.25), 0.5)
			var silver := Props.mat(Color(0.88, 0.9, 0.95), 0.3, 0.6)
			for sx in [-1.0, 1.0]:
				var arm := MeshInstance3D.new()
				var am := BoxMesh.new()
				am.size = Vector3(0.2, 0.55, 0.2)
				arm.mesh = am
				arm.material_override = red
				arm.position = Vector3(sx * 0.27, 0.0, 0.0)
				_icon.add_child(arm)
				var tip := MeshInstance3D.new()
				var tm := BoxMesh.new()
				tm.size = Vector3(0.2, 0.18, 0.2)
				tip.mesh = tm
				tip.material_override = silver
				tip.position = Vector3(sx * 0.27, 0.36, 0.0)
				_icon.add_child(tip)
			var base := MeshInstance3D.new()
			var bm2 := BoxMesh.new()
			bm2.size = Vector3(0.74, 0.2, 0.2)
			base.mesh = bm2
			base.material_override = red
			base.position = Vector3(0.0, -0.3, 0.0)
			_icon.add_child(base)
		"boost":
			var shoe := Props.glow_mat(Color(1.0, 0.5, 0.1), 0.4)
			var sole := Props.mat(Color(0.97, 0.97, 0.95))
			var body := MeshInstance3D.new()
			var sm := CapsuleMesh.new()
			sm.radius = 0.2
			sm.height = 0.8
			body.mesh = sm
			body.rotation_degrees = Vector3(0, 0, 90)
			body.material_override = shoe
			body.position = Vector3(0, 0.05, 0)
			_icon.add_child(body)
			var sl := MeshInstance3D.new()
			var slm := BoxMesh.new()
			slm.size = Vector3(0.84, 0.1, 0.4)
			sl.mesh = slm
			sl.material_override = sole
			sl.position = Vector3(0, -0.16, 0)
			_icon.add_child(sl)
			var wing := MeshInstance3D.new()
			var wm := BoxMesh.new()
			wm.size = Vector3(0.3, 0.3, 0.1)
			wing.mesh = wm
			wing.material_override = sole
			wing.position = Vector3(-0.33, 0.28, 0)
			wing.rotation_degrees = Vector3(0, 0, 25)
			_icon.add_child(wing)
	# ป้ายชื่อลอยเหนือไอเท็ม
	var lb := Label3D.new()
	lb.text = INFO[kind]["label"]
	lb.font = load("res://fonts/Kanit_600SemiBold.ttf") as Font
	lb.font_size = 56
	lb.pixel_size = 0.0075
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.no_depth_test = true
	lb.modulate = col.lightened(0.35)
	lb.outline_modulate = Color(0.05, 0.07, 0.14)
	lb.outline_size = 14
	lb.position = Vector3(0, 0.78, 0)
	add_child(lb)
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.8
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_body_entered)
	_t = randf() * TAU


func _on_body_entered(body: Node3D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	collected.emit(kind)
	queue_free()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	_icon.rotation.y = _t * 2.2
	_icon.position.y = sin(_t * 3.5) * 0.1
