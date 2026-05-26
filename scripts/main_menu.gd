extends Control

# ---------------------------------
# Variables
# ---------------------------------

@onready var play_game_button = %PlayGameButton

@onready var select_level_button = %SelectLevelButton
@onready var select_level_panel = %SelectLevelPanel

@onready var highscore_button = %HighscoreButton
@onready var highscore_panel = %HighscorePanel

@onready var help_button = %HelpButton
@onready var help_panel = %HelpPanel

@onready var settings_button = %SettingsButton
@onready var settings_panel: Panel = %SettingsPanel

@onready var exit_game_button = %ExitGameButton

var panels: Array[CanvasItem]

var level_paths := [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn"
]

# -------------------------
# Setup
# -------------------------

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

	node.visible = true


# ---------------------
# Button actions
# ---------------------

func play_game() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_1.tscn")

func show_levels() -> void:
	show_only(select_level_panel)
	select_level_panel.deselect_all()

func on_level_selected(index: int) -> void:
	if index < 0 or index >= level_paths.size():
		return

	get_tree().change_scene_to_file(level_paths[index])

func view_highscore() -> void:
	show_only(highscore_panel)

func view_help() -> void:
	show_only(help_panel)

func open_settings() -> void:
	
	show_only(settings_panel)

func exit_game() -> void:
	PlatformDetection.exit_game()
