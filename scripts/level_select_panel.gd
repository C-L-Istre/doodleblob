extends PanelContainer

# ──────────────────────────────────────────────────────────────────────────────
# LevelSelectPanel
#
# Display names are derived from filenames automatically:
#   "res://scenes/levels/level_1.tscn"  →  "Level 1"
#   "res://scenes/levels/bonus_cave.tscn"  →  "Bonus Cave"
#
# Inspector setup:
#   level_paths — one entry per playable level, in the order they should appear.
#                 Do NOT include level_template.tscn here.
# ──────────────────────────────────────────────────────────────────────────────

signal level_selected(path: String)
signal panel_closed

@export var level_paths: Array[String] = []

@onready var level_list: ItemList = %LevelList


func _ready() -> void:
	level_list.clear()

	for path in level_paths:
		var display_name := (
			path.get_file()
				.get_basename()
				.replace("_", " ")
				.capitalize()
		)

		level_list.add_item(display_name)
	level_list.focus_exited.connect(_on_level_list_focus_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not level_list.has_focus():
		return

	if event.is_action_pressed("ui_accept"):
		_confirm_selection()
		get_viewport().set_input_as_handled()

func _confirm_selection() -> void:
	var selected := level_list.get_selected_items()
	if selected.is_empty():
		return

	var index := selected[0]

	if index < 0 or index >= level_paths.size():
		return

	level_selected.emit(level_paths[index])

func get_first_level() -> String:
	if level_paths.is_empty():
		return ""
	return level_paths[0]


func grab_list_focus() -> void:
	level_list.grab_focus()

	if level_list.item_count > 0:
		level_list.select(0)


func _on_level_list_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	if index < 0 or index >= level_paths.size():
		return

	level_list.select(index)
	_confirm_selection()


func _on_level_list_focus_exited() -> void:
	deselect_all()
	panel_closed.emit()


func deselect_all() -> void:
	level_list.deselect_all()
