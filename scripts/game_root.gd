extends Control

# ──────────────────────────────────────────────────────────────────────────────
# game_root.gd
#
# Root script for in-game level scenes. Forwards the "pause" input action to
# the PauseMenu CanvasLayer. Attach to the root Control node of each level
# scene that contains a PauseMenu child.
#
# Rename note: previously named control.gd. Renamed to game_root.gd to make
# the intent clear — "Control" describes the node type, not the script's role.
# ──────────────────────────────────────────────────────────────────────────────

@onready var _pause_menu: CanvasLayer = %PauseMenu


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_pause_menu.toggle_pause()
