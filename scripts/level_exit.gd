extends Area2D

# ──────────────────────────────────────────────────────────────────────────────
# LevelExit
#
# Area2D that transitions to the next scene when a body in the "player" group
# enters it. Set next_level_path in the inspector (or leave empty to return to
# the main menu when the player reaches the exit).
# ──────────────────────────────────────────────────────────────────────────────

## Path to the next level scene. Leave empty to return to the main menu.
@export_file("*.tscn") var next_level_path: String = ""


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		call_deferred("_change_level")


func _change_level() -> void:
	# Save score as a high score candidate at each level boundary.
	# Score is NOT reset here — it carries forward to the next level.
	ScoreManager.finish_level()
	if next_level_path.is_empty():
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	else:
		get_tree().change_scene_to_file(next_level_path)
