extends Area2D

# ──────────────────────────────────────────────────────────────────────────────
# LevelExit
#
# Area2D that transitions the player to the next scene when entered.
#
# Inspector setup:
#   next_level_path — scene to load on a normal exit.
#                     Leave empty on the final level: the player will be sent
#                     to game_end.tscn where win_quest_id determines whether
#                     the screen reads "Game Won" or "Game Over".
#
# Signal setup (connect in editor):
#   body_entered → _on_body_entered
# ──────────────────────────────────────────────────────────────────────────────

## Scene to load on a normal exit.
## Leave empty on the final level — falls through to game_end automatically.
@export_file("*.tscn") var next_level_path: String = ""


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		call_deferred("_change_level")


func _change_level() -> void:
	ScoreManager.finish_level()
	if next_level_path.is_empty():
		get_tree().change_scene_to_file("res://scenes/ui/game_end.tscn")
	else:
		get_tree().change_scene_to_file(next_level_path)
