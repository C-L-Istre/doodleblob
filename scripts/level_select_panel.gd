extends PanelContainer

# ──────────────────────────────────────────────────────────────────────────────
# LevelSelectPanel
#
# Embedded panel inside the main menu. Maintains a single source of truth:
# level_paths. The ItemList is rebuilt from that array in _ready() — display
# names are derived automatically from filenames ("level_1.tscn" → "Level 1").
#
# Input model (two separate paths, no overlap):
#   Mouse  — item_clicked signal → _on_level_list_item_clicked → _confirm_selection
#   Keyboard/gamepad — _unhandled_input catches ui_accept while the list has focus
#
# Lifecycle:
#   main_menu calls grab_list_focus() when opening the panel (selects item 0).
#   The ItemList emits focus_exited when the player tabs/clicks away; the panel
#   responds by deselecting and emitting panel_closed so main_menu can hide it.
#
# Signals:
#   level_selected(path) — emitted when the player confirms a level choice.
#   panel_closed         — emitted when the ItemList loses focus externally;
#                          main_menu connects this to _close_all().
#
# Inspector setup:
#   level_paths — one entry per playable level, in display order.
#                 Do NOT include level_template.tscn here.
# ──────────────────────────────────────────────────────────────────────────────

signal level_selected(path: String)
## Emitted when the ItemList loses focus so main_menu can close the panel.
## Connected to main_menu._on_level_select_closed → _close_all().
signal panel_closed

## Ordered list of level scene paths. The ItemList is rebuilt from this array
## every time the panel is ready — no ItemList items need to be set manually.
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

	# focus_exited is connected here rather than in the editor because it drives
	# an auto-close behaviour that is an implementation detail of this script,
	# not a straightforward UI event. Keeping it in code makes the coupling
	# explicit and prevents the scene from appearing to have a side-effect
	# connection that only makes sense in context.
	level_list.focus_exited.connect(_on_level_list_focus_exited)


# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not UIManager.is_menu():
		return
	# Only consume ui_accept when the list actually has keyboard focus so this
	# handler does not interfere with other ui_accept consumers (e.g. buttons).
	if not level_list.has_focus():
		return
	if event.is_action_pressed("ui_accept"):
		_confirm_selection()
		get_viewport().set_input_as_handled()


# ── Public API ────────────────────────────────────────────────────────────────

## Return the first configured level path, or "" if level_paths is empty.
## Used by main_menu's Play Game button to skip the selector entirely.
func get_first_level() -> String:
	if level_paths.is_empty():
		return ""
	return level_paths[0]


## Give keyboard/gamepad focus to the list and pre-select the first item.
## Call this after making the panel visible so navigation starts immediately.
func grab_list_focus() -> void:
	level_list.grab_focus()
	if level_list.item_count > 0:
		level_list.select(0)


## Clear the ItemList selection. Called by main_menu when the panel is closed
## via the Select Level button toggle so stale state does not persist.
func deselect_all() -> void:
	level_list.deselect_all()


# ── Private ───────────────────────────────────────────────────────────────────

func _confirm_selection() -> void:
	var selected := level_list.get_selected_items()
	if selected.is_empty():
		return
	var index := selected[0]
	if index < 0 or index >= level_paths.size():
		return
	level_selected.emit(level_paths[index])


# ── Signal handlers ───────────────────────────────────────────────────────────

## Mouse path: item_clicked fires on single click (connect in editor).
func _on_level_list_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	if index < 0 or index >= level_paths.size():
		return
	level_list.select(index)
	_confirm_selection()


## Auto-close path: fires when the ItemList loses focus to anything external.
## Deselects so a re-open always starts clean, then signals main_menu to hide.
func _on_level_list_focus_exited() -> void:
	deselect_all()
	panel_closed.emit()
