@tool
class_name StarCoin
extends Area3D
## เหรียญดาวความดี — เก็บแล้วดันครูวินัยให้ห่างออกไป + ได้คะแนน

signal collected

var _t := 0.0
var _taken := false
var x_off := 0.0                 # เยื้องจากกึ่งกลางถนน (ใช้ตอนทดสอบ)
var s := 0.0                     # ตำแหน่งตามแนวถนน (ม.)
var _mesh: MeshInstance3D


static func create(pos: Vector3, s_pos := 0.0) -> StarCoin:
	var c := StarCoin.new()
	c.position = pos
	c.s = s_pos
	c._build()
	c.add_to_group("stars")
	return c


func _build() -> void:
	collision_layer = 4          # layer 3 = coin
	collision_mask = 1           # player
	monitoring = true
	monitorable = false
	_mesh = MeshInstance3D.new()
	_mesh.mesh = Props.star_mesh()
	_mesh.material_override = Props.glow_mat(Color(1.0, 0.80, 0.12), 0.7)
	add_child(_mesh)
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.62
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_body_entered)
	_t = randf() * TAU


func _on_body_entered(body: Node3D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	collected.emit()
	queue_free()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	_mesh.rotation.y = _t * 3.0
	_mesh.position.y = sin(_t * 4.0) * 0.08
