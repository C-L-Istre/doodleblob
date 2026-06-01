extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────
# PauseMenu
#
# In-game pause overlay. Handles resume, settings, main menu navigation,
# and exit. toggle_pause() is the public entry point — call it from game_root.gd
# or any script that handles the "pause" input action.
#
# The node's process_mode is set to PROCESS_MODE_ALWAYS so it continues to
# receive input while the scene tree is paused.
# ──────────────────────────────────────────────────────────────────────────────

@onready var _resume_button:   Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _settings_panel:  Panel  = %SettingsPanel
@onready var _menu_button:     Button = %MainMenuButton
@onready var _exit_button:     Button = %ExitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_exit_button.visible = PlatformDetection.can_quit()

	hide()
	_settings_panel.hide()

	_resume_button.pressed.connect(_on_resume_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)


# ── Public API ────────────────────────────────────────────────────────────────

func toggle_pause() -> void:
	if get_tree().paused:
		_resume()
	else:
		_pause()


# ── Private ───────────────────────────────────────────────────────────────────

func _pause() -> void:
	get_tree().paused = true
	show()
	_resume_button.grab_focus()


func _resume() -> void:
	get_tree().paused = false
	hide()


func _on_resume_pressed() -> void:
	_resume()


func _on_settings_pressed() -> void:
	_settings_panel.show()


func _on_menu_pressed() -> void:
	ScoreManager.finish_level()
	ScoreManager.reset_score()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
