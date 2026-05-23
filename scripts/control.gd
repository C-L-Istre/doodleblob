extends Control

@onready var pause_menu: CanvasLayer = %PauseMenu

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_menu.toggle_pause()
