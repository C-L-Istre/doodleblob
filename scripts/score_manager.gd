extends Node

var current_score: int = 0
var high_score: int = 0

const SAVE_PATH := "user://save.cfg"
var config := ConfigFile.new()


func _ready() -> void:
	load_high_score()


# -------------------------
# Add score
# -------------------------

func add_point() -> void:
	current_score += 1

# -------------------------
# High score handling
# -------------------------

func finish_level() -> void:
	if current_score > high_score:
		high_score = current_score
		save_high_score()


func reset_score() -> void:
	current_score = 0


# -------------------------
# Save / Load
# -------------------------

func save_high_score() -> void:
	config.set_value("scores", "high_score", high_score)
	config.save(SAVE_PATH)


func load_high_score() -> void:
	var err = config.load(SAVE_PATH)
	if err == OK:
		high_score = config.get_value("scores", "high_score", 0)
