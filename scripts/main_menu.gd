extends Control

# ──────────────────────────────────────────────────────────────────────────────
# MainMenu
#
# Root script for the main menu scene. Manages visibility switching between
# sub-panels (level select, high score, help, settings) and wires the level
# select panel's signals to scene-loading logic.
#
# Signal connections that cannot go in the editor (sources are child subscenes
# whose signals are not visible in the parent scene's connection dialog):
#   level_select_panel.level_selected → _on_level_selected
#   level_select_panel.panel_closed   → _on_level_select_closed
#
# All button signals are connected in the editor.
# ──────────────────────────────────────────────────────────────────────────────

@onready var level_select_panel: PanelContainer = %LevelSelectPanel
@onready var highscore_panel:    PanelContainer = %HighscorePanel
@onready var exit_button:        Button         = %ExitGameButton

var _panels: Array[CanvasItem]


func _ready() -> void:
	_panels = [%LevelSelectPanel, %HighscorePanel, %HelpPanel, %SettingsPanel]
	exit_button.visible = PlatformDetection.can_quit()
	MenuNav.setup([
		%PlayGameButton,
		%LevelSelectButton,
		%HighscoreButton,
		%HelpButton,
		%SettingsButton,
		%ExitGameButton,
	])
	level_select_panel.level_selected.connect(_on_level_selected)
	level_select_panel.panel_closed.connect(_on_level_select_closed)
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


# ── Button handlers (connect in editor) ───────────────────────────────────────

func _on_play_game_button_pressed() -> void:
	var first_level: String = level_select_panel.get_first_level()
	if first_level.is_empty():
		push_error("MainMenu: no levels configured in LevelSelectPanel.level_paths.")
		return
	ScoreManager.reset_score()
	HealthManager.reset_game()
	QuestManager.reset()
	call_deferred("_load_level", first_level)


func _on_level_select_button_pressed() -> void:
	_toggle_panel(level_select_panel)
	if level_select_panel.visible:
		level_select_panel.grab_list_focus()
	else:
		level_select_panel.deselect_all()

func _ready() -> void:
	panels = [
		select_level_panel,
		highscore_panel,
		help_panel,
		settings_panel
	]
	play_game_button.pressed.connect(play_game)
	select_level_button.pressed.connect(show_levels)
	highscore_button.pressed.connect(view_highscore)
	help_button.pressed.connect(view_help)
	settings_button.pressed.connect(open_settings)
	exit_game_button.pressed.connect(exit_game)

	exit_game_button.visible = PlatformDetection.can_quit()

	highscore_panel.text = "High Score: " + str(ScoreManager.high_score)

	select_level_panel.item_selected.connect(on_level_selected)

# -------------------------
# Show only selected panel
# -------------------------

func show_only(node: CanvasItem) -> void:
	for panel in panels:
		panel.visible = false

func _on_highscore_button_pressed() -> void:
	_toggle_panel(highscore_panel)


func _on_help_button_pressed() -> void:
	_toggle_panel(%HelpPanel)


func _on_settings_button_pressed() -> void:
	_toggle_panel(%SettingsPanel)


func _on_exit_game_button_pressed() -> void:
	PlatformDetection.exit_game()


# ── Level select signal handlers ──────────────────────────────────────────────

## Fires when the player confirms a level in the LevelSelectPanel.
func _on_level_selected(path: String) -> void:
	ScoreManager.reset_score()
	HealthManager.reset_game()
	QuestManager.reset()
	call_deferred("_load_level", path)


## Fires when LevelSelectPanel.panel_closed is emitted (ItemList lost focus).
## Kept as a named handler rather than a lambda so it appears clearly in the
## call stack if the close chain needs debugging.
func _on_level_select_closed() -> void:
	_close_all()


# ── Private ───────────────────────────────────────────────────────────────────

func _load_level(path: String) -> void:
	get_tree().change_scene_to_file(path)
