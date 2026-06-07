extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────
# GameWon
# ──────────────────────────────────────────────────────────────────────────────

## Scene to load when the player clicks Play Again. Set in the Inspector.
@export_file("*.tscn") var restart_scene: String = ""
@export var win_quest_id: String = ""

@onready var win_lose_label: Label = %WinLoseLabel
@onready var exit_button: Button = %ExitButton


func _ready() -> void:
	exit_button.visible = PlatformDetection.can_quit()
	MenuNav.setup([%PlayButton, %MainMenuButton, %ExitButton])

	##if QuestManager.all_complete():
	if QuestManager.is_complete(win_quest_id):
		win_lose_label.text = "Game Won"
	else:
		win_lose_label.text = "Game Over"

func _on_play_button_pressed() -> void:
	if restart_scene.is_empty():
		push_error("GameWon: restart_scene is not set — assign a level path in the Inspector.")
		return
	ScoreManager.finish_level()
	ScoreManager.reset_score()
	HealthManager.reset_game()
	QuestManager.reset()
	get_tree().change_scene_to_file(restart_scene)


func _on_main_menu_button_pressed() -> void:
	ScoreManager.finish_level()
	ScoreManager.reset_score()
	HealthManager.reset_game()
	QuestManager.reset()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_exit_button_pressed() -> void:
	PlatformDetection.exit_game()
