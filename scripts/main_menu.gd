extends Control

# ──────────────────────────────────────────────────────────────────────────────
# MainMenu
# ──────────────────────────────────────────────────────────────────────────────

@onready var level_select_panel: PanelContainer = %LevelSelectPanel
@onready var highscore_panel: PanelContainer = %HighscorePanel
@onready var exit_button:        Button   = %ExitGameButton

# Built from unique-name refs — all panels already have unique_name_in_owner = true
# so no Inspector setup is required.
var _panels: Array[CanvasItem]


func _ready() -> void:
	_panels = [%LevelSelectPanel, %HighscorePanel, %HelpPanel, %SettingsPanel]
	exit_button.visible = PlatformDetection.can_quit()
	MenuNav.setup([
		%PlayGameButton,
		%SelectLevelButton,
		%HighscoreButton,
		%HelpButton,
		%SettingsButton,
		%ExitGameButton,
	])
	level_select_panel.level_selected.connect(_on_level_selected)
	_close_all()

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


# ── Button handlers ───────────────────────────────────────────────────────────

func _on_play_game_button_pressed() -> void:
	var first_level: String = level_select_panel.get_first_level()

	if first_level.is_empty():
		push_error("No levels configured in SelectLevelPanel.")
		return

	ScoreManager.reset_score()
	HealthManager.reset_game()
	QuestManager.reset()

	call_deferred("_load_level", first_level)


func _on_select_level_button_pressed() -> void:
	_toggle_panel(level_select_panel)
	if not level_select_panel.visible:
		level_select_panel.deselect_all()


func _on_level_selected(path: String) -> void:
	ScoreManager.reset_score()
	HealthManager.reset_game()
	QuestManager.reset()

	call_deferred("_load_level", path)


func _on_highscore_button_pressed() -> void:
	_toggle_panel(highscore_panel)


func _on_help_button_pressed() -> void:
	_toggle_panel(%HelpPanel)


func _on_settings_button_pressed() -> void:
	_toggle_panel(%SettingsPanel)


func _on_exit_game_button_pressed() -> void:
	PlatformDetection.exit_game()
	

func _load_level(path: String) -> void:
	get_tree().change_scene_to_file(path)
