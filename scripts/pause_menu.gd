extends CanvasLayer

@onready var resume_button: Button      = %ResumeButton
@onready var settings_button: Button    = %SettingsButton
@onready var settings_panel: Panel      = %SettingsPanel
@onready var main_menu_button: Button   = %MainMenuButton
@onready var exit_button: Button        = %ExitButton

func _ready() -> void:
	_panels      = [%SettingsPanel, %QuestPanel]
	_nav_buttons = [%ResumeButton, %SettingsButton, %QuestButton, %MainMenuButton, %ExitButton]
	exit_button.visible = PlatformDetection.can_quit()
	# Wire styles now while the node is available; focus is grabbed in _pause()
	# because grab_focus() has no effect on hidden nodes.
	MenuNav.style(_nav_buttons)


	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	exit_button.visible = PlatformDetection.can_quit()

	process_mode = Node.PROCESS_MODE_ALWAYS

func toggle_pause() -> void:
	if get_tree().paused:
		_resume()
	else:
		_pause()


func _resume() -> void:
	get_tree().paused = false
	hide()
	settings_panel.hide()

func _on_resume_button_pressed() -> void:
	_resume()

func _on_settings_pressed() -> void:
	settings_panel.show()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_exit_pressed() -> void:
	PlatformDetection.exit_game()
