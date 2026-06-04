extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────
# GameOver
#
# Game over screen. Loaded directly by HealthManager when lives reach zero.
# Saves the final score as a high score candidate on the way back to the menu.
#
# All button signals are connected in the scene editor.
# ──────────────────────────────────────────────────────────────────────────────

@onready var _exit_button: Button = %ExitButton


func _ready() -> void:
	_exit_button.visible = PlatformDetection.can_quit()


# ── Button handlers (connect in editor) ───────────────────────────────────────

func _on_play_button_pressed() -> void:
	ScoreManager.finish_level()
	ScoreManager.reset_score()
	HealthManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/levels/level_1.tscn")

func _on_main_menu_button_pressed() -> void:
	ScoreManager.finish_level()
	ScoreManager.reset_score()
	HealthManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
