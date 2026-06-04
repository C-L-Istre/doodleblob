extends CharacterBody2D

# ──────────────────────────────────────────────────────────────────────────────
# NPC (Triangela)
#
# Basic NPC with proximity-based interaction. When the player enters the
# detection area and presses the interact action, interact() is called,
# which toggles the dialog label.
#
# The player script owns the prompt logic — it calls show_prompt() and
# hide_prompt() when the player enters or leaves range. The prompt label node
# lives here so it appears above this NPC rather than following the player.
#
# Scene setup — add two Label nodes as children, both with unique names:
#   %PromptLabel — positioned above the NPC (e.g. y: -48), visible = false
#   %DialogLabel — positioned above the prompt,           visible = false
#
# Area2D body_entered/exited connected in editor.
# ──────────────────────────────────────────────────────────────────────────────

## Text shown on the prompt when the player is in range.
@export var prompt_text: String = "Press <Interact> to Talk"

## The line of dialog shown when the player interacts.
@export var dialog_text: String = "Hey..."

@onready var _prompt_label: Label = %PromptLabel
@onready var _dialog_label: Label = %DialogLabel


func _ready() -> void:
	_prompt_label.text    = prompt_text
	_prompt_label.visible = false
	_dialog_label.visible = false


# ── Interactable interface ─────────────────────────────────────────────────────

## Called by the player when entering range.
func show_prompt() -> void:
	_prompt_label.visible = true


## Called by the player when leaving range.
func hide_prompt() -> void:
	_prompt_label.visible = false
	_dialog_label.visible = false


## Called by the player when the interact action is pressed.
func interact(_player: Node) -> void:
	_dialog_label.text    = dialog_text
	_dialog_label.visible = not _dialog_label.visible


# ── Detection area callbacks (connect in editor) ──────────────────────────────

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set_interactable(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.clear_interactable(self)
