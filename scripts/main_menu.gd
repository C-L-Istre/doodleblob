extends Control

# ──────────────────────────────────────────────────────────────────────────────
# MainMenu
# ──────────────────────────────────────────────────────────────────────────────

## Scenes to load in order. Add entries here to expose levels in level select.
@export var level_paths: Array[String] = []

@onready var _highscore_panel:    Label    = %HighscorePanel
@onready var _select_level_panel: ItemList = %SelectLevelPanel
@onready var _exit_button:        Button   = %ExitGameButton

# Built from unique-name refs — all panels already have unique_name_in_owner = true
# so no Inspector setup is required.
var _panels: Array[CanvasItem]


func _ready() -> void:
	_panels = [%SelectLevelPanel, %HighscorePanel, %HelpPanel, %SettingsPanel]
	_exit_button.visible = PlatformDetection.can_quit()
	_highscore_panel.text = "High Score: %d" % ScoreManager.high_score
	ScoreManager.high_score_changed.connect(_on_high_score_changed)
	MenuNav.setup([
		%PlayGameButton,
		%SelectLevelButton,
		%HighscoreButton,
		%HelpButton,
		%SettingsButton,
		%ExitGameButton,
	])


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
	if level_paths.is_empty():
		push_error("MainMenu: level_paths is empty — add at least one entry in the Inspector.")
		return
	ScoreManager.reset_score()
	HealthManager.reset_game()
	QuestManager.reset()
	call_deferred("_load_level", level_paths[0])


func _on_select_level_button_pressed() -> void:
	_toggle_panel(_select_level_panel)
	if not _select_level_panel.visible:
		_select_level_panel.deselect_all()


func _on_select_level_panel_item_selected(index: int) -> void:
	if index < 0 or index >= level_paths.size():
		return
	ScoreManager.reset_score()
	HealthManager.reset_game()
	QuestManager.reset()
	call_deferred("_load_level", level_paths[index])


func _on_highscore_button_pressed() -> void:
	_toggle_panel(_highscore_panel)


func _on_help_button_pressed() -> void:
	_toggle_panel(%HelpPanel)


func _on_settings_button_pressed() -> void:
	_toggle_panel(%SettingsPanel)


func _on_exit_game_button_pressed() -> void:
	PlatformDetection.exit_game()


func _on_high_score_changed(new_high: int) -> void:
	_highscore_panel.text = "High Score: %d" % new_high


func _load_level(path: String) -> void:
	get_tree().change_scene_to_file(path)
