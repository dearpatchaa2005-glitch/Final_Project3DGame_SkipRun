class_name Records
extends RefCounted
## =====================================================================
##  บันทึกชื่อผู้เล่นและสถิติทุกรอบที่เล่น (เก็บเป็นไฟล์ JSON ในเครื่อง)
##    Windows: %APPDATA%\Godot\app_userdata\Skip Run\skip_run_records.json
## =====================================================================

const PATH := "user://skip_run_records.json"
const CFG := "user://skip_run.cfg"
const MAX_RUNS := 500
const DEFAULT_NAME := "ผู้เล่น"


static func _load() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {"runs": []}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {"runs": []}
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary and data.get("runs") is Array:
		return data
	return {"runs": []}


static func _save(d: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))


static func clean_name(n: String) -> String:
	var t := n.strip_edges()
	if t.is_empty():
		return DEFAULT_NAME
	return t.substr(0, 20)


static func get_name() -> String:
	var cf := ConfigFile.new()
	if cf.load(CFG) == OK:
		return clean_name(str(cf.get_value("player", "name", DEFAULT_NAME)))
	return DEFAULT_NAME


static func set_name(n: String) -> void:
	var cf := ConfigFile.new()
	cf.load(CFG)
	cf.set_value("player", "name", clean_name(n))
	cf.save(CFG)


static func thai_date(unix: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(unix + 7 * 3600)       # เวลาไทย (UTC+7)
	return "%02d/%02d/%d  %02d:%02d" % [d["day"], d["month"], int(d["year"]) + 543, d["hour"], d["minute"]]


## บันทึกผลหนึ่งรอบของผู้เล่น
static func add_run(player_name: String, distance: int, stars: int, score: int) -> void:
	var d := _load()
	var runs: Array = d["runs"]
	runs.append({"name": clean_name(player_name), "ts": int(Time.get_unix_time_from_system()),
		"dist": distance, "stars": stars, "score": score})
	if runs.size() > MAX_RUNS:
		runs = runs.slice(runs.size() - MAX_RUNS)
	d["runs"] = runs
	_save(d)


## รอบของผู้เล่นคนนั้น เรียงจากล่าสุดไปเก่าสุด
static func runs_for(player_name: String) -> Array:
	var out: Array = []
	var n := clean_name(player_name)
	var runs: Array = _load()["runs"]
	for i in range(runs.size() - 1, -1, -1):
		if str(runs[i].get("name", "")) == n:
			out.append(runs[i])
	return out


static func summary(player_name: String) -> Dictionary:
	var runs := runs_for(player_name)
	var s := {"games": runs.size(), "best_score": 0, "best_dist": 0, "total_stars": 0, "avg_score": 0}
	var total := 0
	for r in runs:
		s["best_score"] = maxi(s["best_score"], int(r.get("score", 0)))
		s["best_dist"] = maxi(s["best_dist"], int(r.get("dist", 0)))
		s["total_stars"] += int(r.get("stars", 0))
		total += int(r.get("score", 0))
	if runs.size() > 0:
		s["avg_score"] = int(round(float(total) / runs.size()))
	return s


static func best_score(player_name: String) -> int:
	return int(summary(player_name)["best_score"])


## อันดับผู้เล่นทุกคน (คะแนนสูงสุดของแต่ละคน)
static func leaderboard(limit := 5) -> Array:
	var by: Dictionary = {}
	for r in _load()["runs"]:
		var n := str(r.get("name", DEFAULT_NAME))
		if not by.has(n):
			by[n] = {"name": n, "best": 0, "games": 0}
		by[n]["best"] = maxi(by[n]["best"], int(r.get("score", 0)))
		by[n]["games"] += 1
	var arr: Array = by.values()
	arr.sort_custom(func(a, b): return a["best"] > b["best"])
	return arr.slice(0, limit)
