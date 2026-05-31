extends Node

# ──────────────────────────────────────────────────────────────────────────────
# ScoreManager  (autoload)
#
# Tracks the current session score and persists the all-time high score between
# sessions. Call add_point() from any pickup or scoring event. Call
# finish_level() when a level ends to commit a new high score if earned.
# ──────────────────────────────────────────────────────────────────────────────

const SAVE_PATH := "user://save.cfg"

var current_score: int = 0
var high_score:    int = 0

var _config := ConfigFile.new()


func _ready() -> void:
	_load_high_score()


# ── Score mutation ─────────────────────────────────────────────────────────────

## Increment the current score by one point.
func add_point() -> void:
	current_score += 1


## Reset the current score to zero (call at the start of a new run/level).
func reset_score() -> void:
	current_score = 0


# ── High score ─────────────────────────────────────────────────────────────────

## Call when a level is completed. Saves a new high score if the current score
## beats the previous record.
func finish_level() -> void:
	if current_score > high_score:
		high_score = current_score
		_save_high_score()


# ── Persistence ───────────────────────────────────────────────────────────────

func _save_high_score() -> void:
	_config.set_value("scores", "high_score", high_score)
	_config.save(SAVE_PATH)


func _load_high_score() -> void:
	if _config.load(SAVE_PATH) == OK:
		high_score = _config.get_value("scores", "high_score", 0)
