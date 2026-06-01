extends Node

signal lives_changed(lives: int)

const STARTING_LIVES := 3
const GAME_OVER_SCENE := "res://scenes/ui/game_over.tscn"

var lives: int = STARTING_LIVES


func reset_game() -> void:
	lives = STARTING_LIVES
	lives_changed.emit(lives)


func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)

	if lives <= 0:
		call_deferred("_go_to_game_over")

func _go_to_game_over() -> void:
	get_tree().change_scene_to_file(GAME_OVER_SCENE)

func gain_life(amount: int = 1) -> void:
	lives += amount
	lives_changed.emit(lives)
