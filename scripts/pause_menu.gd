extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────
# PauseMenu
#
# In-game pause overlay. toggle_pause() is the public entry point — called
# from control_root.gd when the "pause" input action fires.
#
# Scene Inspector setup:
#   Node → Process Mode : Always
#   Visibility          : Hidden
#   SettingsPanel → Visibility : Hidden
# ──────────────────────────────────────────────────────────────────────────────

@onready var settings_panel: PanelContainer  = %SettingsPanel
@onready var quest_panel: PanelContainer = %QuestPanel
@onready var exit_button:    Button = %ExitButton

var _panels:      Array[CanvasItem]
var _nav_buttons: Array[Button]


func _ready() -> void:
	_panels      = [%SettingsPanel, %QuestPanel]
	_nav_buttons = [%ResumeButton, %SettingsButton, %QuestButton, %MainMenuButton, %ExitButton]
	exit_button.visible = PlatformDetection.can_quit()
	# Wire styles now while the node is available; focus is grabbed in _pause()
	# because grab_focus() has no effect on hidden nodes.
	MenuNav.style(_nav_buttons)


# ── Panel management ──────────────────────────────────────────────────────────

func _close_all() -> void:
	for panel in _panels:
		panel.visible = false


func _toggle_panel(node: CanvasItem) -> void:
	if node.visible:
		_close_all()
	else:
		_close_all()
		node.visible = true


# ── Public API ────────────────────────────────────────────────────────────────

func toggle_pause() -> void:
	if get_tree().paused:
		_resume()
	else:
		_pause()


# ── Button handlers ───────────────────────────────────────────────────────────

func _on_resume_button_pressed() -> void:
	_resume()


func _on_settings_button_pressed() -> void:
	_toggle_panel(settings_panel)

func _on_quest_button_pressed() -> void:
	_toggle_panel(quest_panel)


func _on_main_menu_button_pressed() -> void:
	HealthManager.reset_game()
	ScoreManager.finish_level()
	ScoreManager.reset_score()
	QuestManager.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_exit_button_pressed() -> void:
	PlatformDetection.exit_game()


# ── Private ───────────────────────────────────────────────────────────────────

func _pause() -> void:
	get_tree().paused = true
	show()
	MenuNav.focus_first(_nav_buttons)


func _resume() -> void:
	get_tree().paused = false
	hide()
