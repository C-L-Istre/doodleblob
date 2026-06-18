extends Node

# ──────────────────────────────────────────────────────────────────────────────
# ScoreManager  (autoload)
#
# Tracks the current session score, total elapsed time, and a local
# leaderboard of the top MAX_ENTRIES {name, score} entries, persisted in
# user://save.cfg.
#
# high_score is always leaderboard[0].score (or 0 if the leaderboard is
# empty) -- it is not a separate tracked value. A pre-leaderboard save
# (single high_score, no name) is migrated into a one-entry leaderboard on
# first load so existing players keep their record.
#
# Per-level time and score are tracked by level.gd and reported here via
# record_level() when the player exits a level -- see level.gd and
# level_exit.gd. level_records is in-memory only for now (not persisted);
# it exists so a future per-level best-time/best-score display has somewhere
# to read from without further plumbing.
#
# Flow for an end-of-run screen:
#
#   if ScoreManager.qualifies_for_leaderboard(ScoreManager.current_score):
#       # show a name-entry field, then:
#       var rank := ScoreManager.submit_score(player_name)
#
# Connect to score_changed to drive HUD labels reactively rather than polling
# current_score every frame:
#
#   func _ready() -> void:
#       ScoreManager.score_changed.connect(_on_score_changed)
#
#   func _on_score_changed(new_score: int) -> void:
#       %ScoreLabel.text = str(new_score)
# ──────────────────────────────────────────────────────────────────────────────

signal score_changed(new_score: int)
signal high_score_changed(new_high: int)
signal leaderboard_changed

const SAVE_PATH := "user://save.cfg"
const MAX_ENTRIES := 10
const DEFAULT_NAME := "Player"

var current_score: int = 0
var high_score:    int = 0

## Total seconds across all levels exited so far this run.
var total_time: float = 0.0

## level_id -> {"time": float, "score": int}. In-memory only, cleared on
## reset_score(). Populated by record_level().
var level_records: Dictionary = {}

## Sorted descending by score. Each entry: {"name": String, "score": int}
var leaderboard: Array[Dictionary] = []

var _config := ConfigFile.new()


func _ready() -> void:
	_load_leaderboard()


# ── Score mutation ─────────────────────────────────────────────────────────────

## Increment the current score by one point.
func add_point() -> void:
	add_points(1)


## Increment the current score by an arbitrary amount. Used for quest
## rewards and any other lump-sum award.
func add_points(amount: int) -> void:
	if amount == 0:
		return
	current_score += amount
	score_changed.emit(current_score)


## Reset all per-run tracking to zero (call at the start of a new run).
func reset_score() -> void:
	current_score = 0
	total_time     = 0.0
	level_records.clear()
	score_changed.emit(current_score)


## Call when a level transition occurs (next level, return to menu). Kept as
## a no-op hook for existing call sites -- the leaderboard requires a player
## name and is only written via submit_score() at the end of a run.
func finish_level() -> void:
	pass


## Record one level's elapsed time and score delta. Called by level_exit.gd
## via the outgoing level's record_progress(). Adds `time` to total_time and
## stores both values under level_id for future per-level displays.
func record_level(level_id: String, time: float, score_delta: int) -> void:
	total_time += time
	level_records[level_id] = { "time": time, "score": score_delta }


## Format a duration in seconds as "MM:SS" for display.
func format_time(seconds: float) -> String:
	var total_seconds: int = int(seconds)
	var minutes: int = int(total_seconds / 60.0)
	var secs: int = total_seconds % 60
	return "%02d:%02d" % [minutes, secs]


# ── Leaderboard ───────────────────────────────────────────────────────────────

## True if `score` would land in the top MAX_ENTRIES. Use this to decide
## whether to show a name-entry prompt on the end screen.
func qualifies_for_leaderboard(score: int) -> bool:
	if score <= 0:
		return false
	if leaderboard.size() < MAX_ENTRIES:
		return true
	return score > leaderboard[-1]["score"]


## Insert current_score under player_name, re-sort, trim to MAX_ENTRIES,
## persist, and update high_score. Returns the 1-based rank, or -1 if the
## score did not qualify (leaderboard is unchanged in that case).
func submit_score(player_name: String) -> int:
	if not qualifies_for_leaderboard(current_score):
		return -1

	var trimmed_name: String = player_name.strip_edges()
	if trimmed_name.is_empty():
		trimmed_name = DEFAULT_NAME

	var entry := { "name": trimmed_name, "score": current_score }
	leaderboard.append(entry)
	leaderboard.sort_custom(func(a, b): return a["score"] > b["score"])
	if leaderboard.size() > MAX_ENTRIES:
		leaderboard.resize(MAX_ENTRIES)

	_save_leaderboard()

	var new_high: int = leaderboard[0]["score"]
	if new_high != high_score:
		high_score = new_high
		high_score_changed.emit(high_score)
	leaderboard_changed.emit()

	return leaderboard.find(entry) + 1


# ── Persistence ───────────────────────────────────────────────────────────────

func _save_leaderboard() -> void:
	_config.set_value("leaderboard", "entries", leaderboard)
	_config.save(SAVE_PATH)


func _load_leaderboard() -> void:
	if _config.load(SAVE_PATH) != OK:
		return

	var raw: Variant = _config.get_value("leaderboard", "entries", [])
	for entry in raw:
		if entry is Dictionary:
			leaderboard.append({
				"name":  str(entry.get("name", DEFAULT_NAME)),
				"score": int(entry.get("score", 0)),
			})

	# Migrate a pre-leaderboard save (single high_score, no name) so existing
	# players don't lose their record the first time this loads.
	if leaderboard.is_empty():
		var legacy_high: int = _config.get_value("scores", "high_score", 0)
		if legacy_high > 0:
			leaderboard.append({ "name": DEFAULT_NAME, "score": legacy_high })

	leaderboard.sort_custom(func(a, b): return a["score"] > b["score"])
	if not leaderboard.is_empty():
		high_score = leaderboard[0]["score"]
