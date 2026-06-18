extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────
# DialogBox
#
# Screen-space dialog UI with branching tree support.
# Lives as a child of ControlRoot so it renders over everything.
#
# Flow:
#   NPC.interact(player) → player.start_dialog(data)
#     → DialogBox.start(data)   → dialog_started emitted  → Player freezes
#     → typewriter plays        → choices appear OR continue prompt
#     → player navigates with ui_up/ui_down
#     → player confirms with interact (F/Y) OR ui_accept (Enter/A)
#     → dialog_ended emitted    → Player restores input
#
# Input note — why interact and ui_accept are separate actions:
#   jump is bound to A/Space, so interact cannot also use those keys without
#   causing simultaneous jump+interact near an NPC. interact stays on F/Y
#   for gameplay triggering; ui_accept is handled here as a second path so
#   keyboard (Enter) and gamepad (A) feel consistent with menus.
#
# Scene setup — expected child nodes (unique_name_in_owner = true):
#   %SpeakerLabel      : Label         — NPC name
#   %PortraitRect      : TextureRect   — NPC portrait; hidden when null
#   %DialogLabel       : Label         — current node text
#   %ChoicesContainer  : VBoxContainer — choice rows; visible only when branching
#   %ContinueLabel     : Label         — "Continue" / "Close"; visible only for linear nodes
# ──────────────────────────────────────────────────────────────────────────────

## Emitted when a conversation begins. Player connects to freeze input.
signal dialog_started

## Emitted when the last node is dismissed. Player connects to restore input.
signal dialog_ended

## Characters revealed per second during the typewriter effect.
@export var chars_per_second: float = 48.0

## Texture used as the cursor beside the selected choice row.
@export var choice_cursor_texture: Texture2D

@onready var speaker_label:     Label         = %SpeakerLabel
@onready var portrait_rect:     TextureRect   = %PortraitRect
@onready var dialog_label:      Label         = %DialogLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var continue_label:    Label         = %ContinueLabel

var _data:            DialogData
var _node_map:        Dictionary           # String → DialogNode
var _current_node:    DialogNode
var _is_typing:       bool              = false
var _char_timer:      float             = 0.0
var _char_index:      int               = 0
var _full_text:       String            = ""
var _showing_choices: bool              = false
var _selected_choice: int               = 0
## Subset of _current_node.choices that pass their condition check.
## All choice-related indexing uses this list, not the raw node list.
var _visible_choices: Array[DialogChoice] = []


# ── Public API ─────────────────────────────────────────────────────────────────

## Start a conversation. Called by the player on behalf of an NPC.
func start(data: DialogData) -> void:
	if data.nodes.is_empty():
		return

	_data = data
	_build_node_map()

	speaker_label.text        = data.speaker
	portrait_rect.texture     = data.portrait
	portrait_rect.visible     = data.portrait != null
	continue_label.visible    = false
	choices_container.visible = false

	show()
	await get_tree().process_frame
	dialog_started.emit()
	_goto_node(data.start_node)


## Advance or confirm. Routed here by the player when the interact action fires.
##   Typing         → skip to full text immediately.
##   Choices shown  → confirm the currently selected choice.
##   Linear prompt  → advance to next node, or close if terminal.
func advance() -> void:
	if _is_typing:
		_finish_typing()
		return

	if _showing_choices:
		_confirm_choice()
		return

	if _current_node == null or _current_node.next == "":
		_close()
	else:
		_goto_node(_current_node.next)


# ── Input — choice navigation ──────────────────────────────────────────────────


func _unhandled_input(event: InputEvent) -> void:
	if not UIManager.is_menu():
		return
	if not visible:
		return

	# ui_accept (Enter / A button) mirrors the interact action so players can
	# use standard menu-confirm keys to advance dialog without pressing F/Y.
	# interact itself is handled by player.gd to avoid binding it to A/Space
	# which would also trigger jump.
	if event.is_action_pressed("ui_accept"):
		advance()
		get_viewport().set_input_as_handled()
		return

	if not _showing_choices:
		return

	if event.is_action_pressed("ui_up"):
		_selected_choice = max(0, _selected_choice - 1)
		_update_choice_highlights()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_selected_choice = min(_visible_choices.size() - 1, _selected_choice + 1)
		_update_choice_highlights()
		get_viewport().set_input_as_handled()


# ── Private: typewriter ────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _is_typing:
		return

	_char_timer += delta
	var chars_to_add: int = int(_char_timer * chars_per_second)
	if chars_to_add < 1:
		return

	_char_timer = 0.0
	_char_index = min(_char_index + chars_to_add, _full_text.length())
	dialog_label.text = _full_text.left(_char_index)

	if _char_index >= _full_text.length():
		_finish_typing()


func _show_text(text: String) -> void:
	_full_text                = text
	_char_index               = 0
	_char_timer               = 0.0
	_is_typing                = true
	dialog_label.text         = ""
	continue_label.visible    = false
	choices_container.visible = false


func _finish_typing() -> void:
	_is_typing        = false
	dialog_label.text = _full_text

	if _current_node.choices.is_empty():
		# Linear node — show continue/close prompt.
		continue_label.text    = "Continue [Interact]" if _current_node.next != "" else "Close [Interact]"
		continue_label.visible = true
	else:
		# Branching node — filter by quest conditions then show.
		_show_choices()


# ── Private: branching ─────────────────────────────────────────────────────────

func _build_node_map() -> void:
	_node_map = {}
	for node: DialogNode in _data.nodes:
		_node_map[node.node_id] = node


func _goto_node(node_id: String) -> void:
	if not _node_map.has(node_id):
		push_warning("DialogBox: unknown node_id '%s' — closing." % node_id)
		_close()
		return

	_current_node             = _node_map[node_id]
	_visible_choices          = []
	_showing_choices          = false
	choices_container.visible = false

	# Fire the node's quest event immediately on entry, before the typewriter.
	QuestManager.fire_event(_current_node.quest_event)

	_show_text(_current_node.text)


func _show_choices() -> void:
	# Build the filtered list — hide any choice whose condition isn't met.
	_visible_choices = []
	for choice: DialogChoice in _current_node.choices:
		if QuestManager.check_condition(choice.condition):
			_visible_choices.append(choice)

	# If all choices were filtered out, fall through to linear behaviour.
	if _visible_choices.is_empty():
		_showing_choices       = false
		var has_next: bool     = _current_node.next != ""
		continue_label.text    = "Continue [Interact]" if has_next else "Close [Interact]"
		continue_label.visible = true
		return

	_showing_choices = true
	_selected_choice = 0

	# Rebuild choice rows — free() removes old ones immediately so
	# get_children() is clean before we add new ones.
	for child in choices_container.get_children():
		child.free()

	# Inherit the dialog font so choices visually match the dialog text.
	var font: Font = dialog_label.get_theme_font("font")

	for choice: DialogChoice in _visible_choices:
		var row := HBoxContainer.new()

		var cursor := TextureRect.new()
		cursor.texture            = choice_cursor_texture
		cursor.visible            = false
		cursor.custom_minimum_size = Vector2(8, 8)

		var lbl := Label.new()
		lbl.text = choice.text
		if font:
			lbl.add_theme_font_override("font", font)

		row.add_child(cursor)
		row.add_child(lbl)
		choices_container.add_child(row)

	choices_container.visible = true
	_update_choice_highlights()


func _update_choice_highlights() -> void:
	var rows: Array = choices_container.get_children()
	for i in rows.size():
		var row    := rows[i] as HBoxContainer
		var cursor := row.get_child(0) as TextureRect
		var lbl    := row.get_child(1) as Label
		cursor.visible = (i == _selected_choice)
		lbl.text       = _visible_choices[i].text


func _confirm_choice() -> void:
	var choice: DialogChoice = _visible_choices[_selected_choice]

	# Fire the choice's quest event before navigating away.
	QuestManager.fire_event(choice.quest_event)

	if choice.next == "":
		_close()
	else:
		_goto_node(choice.next)


func _close() -> void:
	_node_map                 = {}
	_current_node             = null
	_visible_choices          = []
	_showing_choices          = false
	choices_container.visible = false
	hide()
	dialog_ended.emit()
