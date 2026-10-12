@tool
class_name RoadPath
extends RefCounted
## =====================================================================
##  เส้นทางถนน (เส้นกึ่งกลาง) ที่ประกอบด้วยช่วงตรงสลับช่วงโค้ง
##  ทุกอย่างในเกม (ผู้เล่น ครู สิ่งกีดขวาง ดาว กล้อง ถนน ตึก) อิงตาม
##    s = ระยะที่เดินทางไปตามถนน (เมตร)    x = ระยะเยื้องซ้าย-ขวาจากเส้นกึ่งกลาง
##  ทิศหันของถนน (heading) ψ: ψ = 0 คือมุ่งไป -Z, ψ เพิ่ม = เลี้ยวซ้าย
## =====================================================================

## ตัวที่ใช้งานอยู่ตอนนี้ (main.gd ตั้งค่าให้) — ให้ Obstacle/Player ดึงไปใช้ได้เลย
static var active: RoadPath

var curves_enabled := true
var straight_start := 150.0          # ช่วงตรงตอนเริ่มเกม (ม.)

var _segs: Array[Dictionary] = []    # {s0, len, k, x, z, psi}
var _rng := RandomNumberGenerator.new()
var _built_to := 0.0


func reset(seed_value := 0) -> void:
	_rng.seed = seed_value if seed_value != 0 else randi()
	_segs.clear()
	_built_to = 0.0
	_add_seg(straight_start if curves_enabled else 100000.0, 0.0)


func _add_seg(length: float, k: float) -> void:
	var x := 0.0
	var z := 0.0
	var psi := 0.0
	if not _segs.is_empty():
		var last: Dictionary = _segs.back()
		var e := _eval(last, last["len"])
		x = e[0]
		z = e[1]
		psi = e[2]
	_segs.append({"s0": _built_to, "len": length, "k": k, "x": x, "z": z, "psi": psi})
	_built_to += length


## เติมเส้นทางให้ยาวถึง s_max
func ensure(s_max: float) -> void:
	while _built_to < s_max:
		var last: Dictionary = _segs.back()
		if absf(float(last["k"])) > 0.0:
			_add_seg(_rng.randf_range(80.0, 160.0), 0.0)          # หลังโค้งต่อด้วยทางตรง
		else:
			var psi_end: float = _eval(last, last["len"])[2]
			var dir := 1.0 if _rng.randf() < 0.5 else -1.0
			if absf(psi_end) > 0.7:
				dir = -signf(psi_end)                              # ดึงทิศกลับให้ถนนไม่วนไปไกล
			var radius := _rng.randf_range(65.0, 95.0)
			var angle := deg_to_rad(_rng.randf_range(35.0, 80.0))
			_add_seg(radius * angle, dir / radius)


## [x, z, psi] ที่ระยะ t จากต้นช่วง
func _eval(seg: Dictionary, t: float) -> Array:
	var k: float = seg["k"]
	var psi0: float = seg["psi"]
	if absf(k) < 0.000001:
		return [seg["x"] - sin(psi0) * t, seg["z"] - cos(psi0) * t, psi0]
	var psi := psi0 + k * t
	return [seg["x"] + (cos(psi) - cos(psi0)) / k, seg["z"] - (sin(psi) - sin(psi0)) / k, psi]


func _find(s: float) -> Dictionary:
	ensure(s + 300.0)
	var lo := 0
	var hi := _segs.size() - 1
	while lo < hi:
		var mid := (lo + hi + 1) >> 1
		if float(_segs[mid]["s0"]) <= s:
			lo = mid
		else:
			hi = mid - 1
	return _segs[lo]


## [x, z, psi] ที่ระยะ s
func _at(s: float) -> Array:
	if _segs.is_empty():
		reset(1)
	if s < 0.0:
		return [0.0, -s, 0.0]                    # ก่อนจุดเริ่ม: ต่อออกไปทาง +Z
	var seg := _find(s)
	return _eval(seg, s - float(seg["s0"]))


## ตำแหน่งบนถนนที่ระยะ s เยื้องไปทางขวา x เมตร (y = 0)
func pos(s: float, x := 0.0) -> Vector3:
	var a := _at(s)
	var psi: float = a[2]
	return Vector3(a[0] + cos(psi) * x, 0.0, a[1] - sin(psi) * x)


## ทิศหัน (หมุนรอบแกน Y) ที่ระยะ s
func yaw(s: float) -> float:
	return float(_at(s)[2])


func curvature(s: float) -> float:
	if s < 0.0:
		return 0.0
	return float(_find(s)["k"])
