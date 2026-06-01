extends Control

# ──────────────────────────────────────────────────────────────────────────────
# MainMenu
#
# Manages the main menu. Handles panel visibility switching (level select,
# high score, help, settings) and navigation to levels by path.
#
# To add levels, append paths to `level_paths`. The ItemList in the level
# select panel will populate automatically.
# ──────────────────────────────────────────────────────────────────────────────

# ── Level list ────────────────────────────────────────────────────────────────
# Add one entry per level in the order they should appear in the level select.

var level_paths: Array[String] = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
]

# ── Node references ───────────────────────────────────────────────────────────

@onready var _play_button:         Button     = %PlayGameButton
@onready var _select_level_button: Button     = %SelectLevelButton
@onready var _select_level_panel:  ItemList   = %SelectLevelPanel
@onready var _highscore_button:    Button     = %HighscoreButton
@onready var _highscore_panel:     Label      = %HighscorePanel
@onready var _help_button:         Button     = %HelpButton
@onready var _help_panel:          Control    = %HelpPanel
@onready var _settings_button:     Button     = %SettingsButton
@onready var _settings_panel:      Panel      = %SettingsPanel
@onready var _exit_button:         Button     = %ExitGameButton

var _panels: Array[CanvasItem]


# ── Setup ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_exit_button.visible = PlatformDetection.can_quit()

	_panels = [
		_select_level_panel,
		_highscore_panel,
		_help_panel,
		_settings_panel,
	]

	_play_button.pressed.connect(_on_play_pressed)
	_select_level_button.pressed.connect(_on_select_level_pressed)
	_highscore_button.pressed.connect(_on_highscore_pressed)
	_help_button.pressed.connect(_on_help_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)

	_highscore_panel.text = "High Score: %d" % ScoreManager.high_score
	ScoreManager.high_score_changed.connect(_on_high_score_changed)

	_select_level_panel.item_selected.connect(_on_level_selected)

# ── Panel management ──────────────────────────────────────────────────────────

# Hide every panel.
func _close_all() -> void:
	for panel in _panels:
		panel.visible = false


# Open `node` and close everything else.
# If `node` is already visible, close everything instead (toggle behaviour).
func _toggle_panel(node: CanvasItem) -> void:
	if node.visible:
		_close_all()
	else:
		_close_all()
		node.visible = true


# ── Button handlers ───────────────────────────────────────────────────────────

func _on_play_pressed() -> void:
	ScoreManager.reset_score()
	HealthManager.reset_game()
	call_deferred("_load_level", level_paths[0])


func _on_select_level_pressed() -> void:
	_toggle_panel(_select_level_panel)
	if not _select_level_panel.visible:
		_select_level_panel.deselect_all()


func _on_level_selected(index: int) -> void:
	if index < 0 or index >= level_paths.size():
		return

	ScoreManager.reset_score()
	HealthManager.reset_game()
	call_deferred("_load_level", level_paths[index])


func _load_level(path: String) -> void:
	get_tree().change_scene_to_file(path)


func _on_highscore_pressed() -> void:
	_toggle_panel(_highscore_panel)


func _on_help_pressed() -> void:
	_toggle_panel(_help_panel)


func _on_settings_pressed() -> void:
	_toggle_panel(_settings_panel)


func _on_exit_pressed() -> void:
	PlatformDetection.exit_game()


func _on_high_score_changed(new_high: int) -> void:
	_highscore_panel.text = "High Score: %d" % new_high
