extends Control

# ──────────────────────────────────────────────────────────────────────────────
# control_root.gd
#
# Root script for in-game level scenes. Forwards the "pause" input action to
# the PauseMenu CanvasLayer. Attach to the root Control node of each level
# scene that contains a PauseMenu child.
#
# ──────────────────────────────────────────────────────────────────────────────

@onready var _pause_menu: CanvasLayer = %PauseMenu


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_pause_menu.toggle_pause()
