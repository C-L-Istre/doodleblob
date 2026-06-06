extends CharacterBody2D

# ──────────────────────────────────────────────────────────────────────────────
# NPC (Triangela)
#
# Proximity-based interactable NPC. Registers itself with the player when in
# range so the player's "interact" action opens the dialog box.
#
# Set dialog_data in the Inspector — either inline or as a saved .tres resource.
# Set prompt_text to the label shown above the NPC when the player is in range.
#
# Scene setup:
#   %PromptLabel  : Label   — world-space prompt above NPC, visible = false
#   Area2D        : Area2D  — detection area; body_entered/exited connected
#                             in editor
# ──────────────────────────────────────────────────────────────────────────────

## Conversation data. Set in the Inspector or assign a saved .tres resource.
@export var dialog_data: DialogData

## Label shown above the NPC when the player is in range.
@export var prompt_text: String = "Press [F] to Talk"

@onready var _prompt_label: Label = %PromptLabel


func _ready() -> void:
	_prompt_label.text    = prompt_text
	_prompt_label.visible = false


# ── Interactable interface ─────────────────────────────────────────────────────

## Called by the player when entering range.
func show_prompt() -> void:
	_prompt_label.visible = true


## Called by the player when leaving range.
func hide_prompt() -> void:
	_prompt_label.visible = false


## Called by the player when the interact action is pressed.
func interact(player: Node) -> void:
	if dialog_data:
		player.start_dialog(dialog_data)


# ── Detection area callbacks (connect in editor) ──────────────────────────────

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set_interactable(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.clear_interactable(self)
