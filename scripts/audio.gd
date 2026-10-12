extends Node
## เล่นเสียงเอฟเฟกต์ (autoload "Audio") — ดัดแปลงจาก Kenney Starter Kit 3D Platformer
## ใช้:  Audio.play("res://sounds/coin.ogg")

var num_players := 12
var bus := "Master"

var available: Array[AudioStreamPlayer] = []   # ตัวเล่นที่ว่างอยู่
var queue: Array[String] = []
var _opts: Array = []                  # คิวเสียงที่รอเล่น
var _cache: Dictionary = {}
var _music: AudioStreamPlayer
var music_muted := false
var _music_db := -10.0
const BASE_DB := -4.0      # ไฟล์เสียงถูกปรับให้ดังสุดที่ -1 dB แล้ว ลดตรงนี้ให้พอดี


func _ready() -> void:
	for i in num_players:
		var p := AudioStreamPlayer.new()
		add_child(p)
		available.append(p)
		p.volume_db = BASE_DB
		p.finished.connect(_on_stream_finished.bind(p))
		p.bus = bus
	_music = AudioStreamPlayer.new()
	_music.bus = bus
	_music.volume_db = _music_db
	add_child(_music)
	var m := load("res://sounds/music.ogg")
	if m is AudioStreamOggVorbis:
		(m as AudioStreamOggVorbis).loop = true
	_music.stream = m
	_music.play()


func _on_stream_finished(stream: AudioStreamPlayer) -> void:
	available.append(stream)


## pitch = 0 -> สุ่มเล็กน้อย | vol = ความดังเพิ่ม/ลด (dB)
func play(sound_path: String, pitch := 0.0, vol := 0.0) -> void:
	queue.append(sound_path)
	_opts.append([pitch, vol])


## เพลงพื้นหลัง: เบาลงตอนอ่านเนื้อเรื่อง ดังขึ้นตอนวิ่ง
func music_level(db: float) -> void:
	_music_db = db
	if _music != null:
		var tw := create_tween()
		tw.tween_property(_music, "volume_db", -80.0 if music_muted else db, 0.5)


func toggle_music() -> bool:
	music_muted = not music_muted
	music_level(_music_db)
	return music_muted


func _process(_delta: float) -> void:
	if not queue.is_empty() and not available.is_empty():
		var path: String = queue.pop_front()
		var o: Array = _opts.pop_front()
		if not _cache.has(path):
			_cache[path] = load(path)
		var p: AudioStreamPlayer = available.pop_front()
		p.stream = _cache[path]
		p.pitch_scale = randf_range(0.92, 1.08) if float(o[0]) <= 0.0 else float(o[0])
		p.volume_db = BASE_DB + float(o[1])
		p.play()
