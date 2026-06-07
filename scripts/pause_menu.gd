extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────
# PauseMenu
#
# In-game pause overlay. toggle_pause() is the public entry point — called
# from control_root.gd when the "pause" input action fires.
#
# Scene Inspector setup (do not set these in code):
#   Node → Process Mode : Always   (keeps input alive while tree is paused)
#   Visibility          : Hidden   (starts hidden; shown by toggle_pause)
#   SettingsPanel → Visibility : Hidden
#
# All button signals are connected in the scene editor.
# ──────────────────────────────────────────────────────────────────────────────

@onready var _settings_panel: Panel  = %SettingsPanel
@onready var _exit_button:    Button = %ExitButton

var _panels: Array[CanvasItem]

# Cached button list — defined once here so _ready and _pause stay in sync.
var _nav_buttons: Array[Button]


func _ready() -> void:
	_panels      = [%SettingsPanel]
	_nav_buttons = [%ResumeButton, %SettingsButton, %MainMenuButton, %ExitButton]

	_exit_button.visible = PlatformDetection.can_quit()

	# Wire hover-matching focus styles now while the node is available.
	# focus_first() is deferred to _pause() since the menu starts hidden —
	# grab_focus() has no effect on non-visible nodes.
	MenuNav.style(_nav_buttons)


# ── Panel management ─────────────────────────────────────────────────────────

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


# ── Button handlers (connect in editor) ───────────────────────────────────────

func _on_resume_button_pressed() -> void:
	_resume()


func _on_settings_button_pressed() -> void:
	_toggle_panel(_settings_panel)


func _on_main_menu_button_pressed() -> void:
	HealthManager.reset_game()
	ScoreManager.finish_level()
	ScoreManager.reset_score()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_exit_button_pressed() -> void:
	PlatformDetection.exit_game()


# ── Private ───────────────────────────────────────────────────────────────────

func _pause() -> void:
	get_tree().paused = true
	show()
	# Grab focus on the first visible button now that the menu is visible.
	MenuNav.focus_first(_nav_buttons)


func _resume() -> void:
	get_tree().paused = false
	hide()
