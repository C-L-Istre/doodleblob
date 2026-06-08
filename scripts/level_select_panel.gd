extends PanelContainer

# ──────────────────────────────────────────────────────────────────────────────
# LevelSelectPanel
#
# Maintains a single source of truth: level_paths. The ItemList is rebuilt
# from that array every time the panel is ready so the two can never drift.
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

## Ordered list of level scene paths. This is the only list to maintain —
## the display names shown in the ItemList are derived from these paths.
@export var level_paths: Array[String] = []

@onready var level_list: ItemList = %LevelList


func _ready() -> void:
	level_list.clear()
	for path in level_paths:
		var display_name: String = (
			path.get_file()   # "level_1.tscn"
				.get_basename()   # "level_1"
				.replace("_", " ")  # "level 1"
				.capitalize()     # "Level 1"
		)
		level_list.add_item(display_name)


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
