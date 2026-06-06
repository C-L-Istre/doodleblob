extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────
# DialogBox
#
# Screen-space dialog UI. Lives as a child of ControlRoot in the level scene
# so it renders over everything at any resolution and survives camera movement.
#
# Flow:
#   NPC.interact(player) → player.start_dialog(data)
#     → DialogBox.start(data)
#     → dialog_started emitted → Player freezes input
#     → player advances lines with the "interact" action
#     → dialog_ended emitted → Player restores input
#
# Scene setup — expected child nodes (all unique_name_in_owner = true):
#   %SpeakerLabel    : Label          — NPC name
#   %PortraitRect    : TextureRect    — NPC portrait; hidden when portrait = null
#   %DialogLabel     : Label          — current line text
#   %ContinueLabel   : Label          — "▼" or "[F]" prompt; hidden while typing
#
# The root CanvasLayer should be set:
#   visible     = false   (in the scene; shown by start())
#   layer       = 5       (above game world, below PauseMenu at layer 10)
#   process_mode = Always (so input works if the tree is ever paused)
# ──────────────────────────────────────────────────────────────────────────────

## Emitted when a conversation begins. Player connects to this to freeze input.
signal dialog_started

## Emitted when the last line is dismissed. Player connects to restore input.
signal dialog_ended

## Characters revealed per second during the typewriter effect.
@export var chars_per_second: float = 40.0

@onready var speaker_label:  Label       = %SpeakerLabel
@onready var portrait_rect:  TextureRect = %PortraitRect
@onready var dialog_label:   Label       = %DialogLabel
@onready var continue_label: Label       = %ContinueLabel

var _lines:        Array[String] = []
var _current_line: int           = 0
var _is_typing:    bool          = false
var _char_timer:   float         = 0.0
var _char_index:   int           = 0
var _full_text:    String        = ""

# ── Public API ────────────────────────────────────────────────────────────────

## Start a conversation. Called by the player on behalf of an NPC.
## Does nothing if data has no lines.
func start(data: DialogData) -> void:
	if data.lines.is_empty():
		return

	_lines = data.lines
	_current_line = 0

	speaker_label.text = data.speaker
	portrait_rect.texture = data.portrait
	portrait_rect.visible = data.portrait != null
	continue_label.visible = false

	show()

	# Wait one frame after show() so the label's layout is ready before
	# the typewriter starts writing. Without this, text may not appear.
	await get_tree().process_frame

	dialog_started.emit()
	_show_line(_lines[0])


## Advance to the next line, or close if on the last line.
## Called by the player when the interact action is pressed.
func advance() -> void:
	if _is_typing:
		_finish_typing()
		return

	_current_line += 1

	if _current_line >= _lines.size():
		_close()
	else:
		_show_line(_lines[_current_line])


# ── Private ───────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _is_typing:
		return

	_char_timer += delta

	var chars_to_add: int = int(_char_timer * chars_per_second)
	if chars_to_add < 1:
		return

	_char_timer   = 0.0
	_char_index   = min(_char_index + chars_to_add, _full_text.length())
	dialog_label.text = _full_text.left(_char_index)

	if _char_index >= _full_text.length():
		_finish_typing()


func _show_line(text: String) -> void:
	_full_text      = text
	_char_index     = 0
	_char_timer     = 0.0
	_is_typing      = true
	dialog_label.text      = ""
	continue_label.visible = false


func _finish_typing() -> void:
	_is_typing              = false
	dialog_label.text      = _full_text
	continue_label.visible = true


func _close() -> void:
	_lines = []
	hide()
	dialog_ended.emit()
