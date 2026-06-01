extends CanvasLayer

@onready var _menu_button:     Button = %MainMenuButton
@onready var _exit_button:     Button = %ExitButton

func _ready() -> void:
	_menu_button.pressed.connect(_on_menu_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)

func _on_menu_pressed() -> void:
	ScoreManager.finish_level()
	ScoreManager.reset_score()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
