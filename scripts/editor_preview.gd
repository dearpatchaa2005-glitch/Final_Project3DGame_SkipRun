@tool
class_name EditorPreview
extends Node3D
## ฉากตัวอย่างที่มองเห็นเฉพาะใน Godot Editor (ถนน ตึก รถ คนเดิน สิ่งกีดขวาง ดาว ไอเท็ม)
## ไว้ให้เปิดดูและแก้ไขโมเดลต่าง ๆ ได้เหมือนวางฉากเอง
## ตอนกดเล่นเกมจริง โหนดนี้จะซ่อนและลบตัวเองทิ้ง เพราะเกมสร้างถนนและสิ่งกีดขวางด้วยโค้ดแบบสุ่มไม่รู้จบ
## (ถ้าอยากซ่อนใน Editor ให้ปิดตา Visible ของโหนดนี้)


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		visible = false


func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()
