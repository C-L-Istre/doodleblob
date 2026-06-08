extends PanelContainer

signal level_selected(path: String)

@export var level_paths: Array[String] = []

@onready var level_list: ItemList = %LevelList

func get_first_level() -> String:
	if level_paths.is_empty():
		return ""
	return level_paths[0]


func _on_level_select_list_item_selected(index: int) -> void:
	if index < 0 or index >= level_paths.size():
		return

	level_selected.emit(level_paths[index])


func deselect_all() -> void:
	level_list.deselect_all()
