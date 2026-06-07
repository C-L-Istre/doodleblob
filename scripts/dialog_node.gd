class_name DialogNode
extends Resource

# ──────────────────────────────────────────────────────────────────────────────
# DialogNode
#
# One node in a branching dialog tree. Every node typewriters its text,
# then does one of two things:
#
#   choices non-empty → show choice buttons; player picks one.
#   choices empty     → show "Continue / Close [F]" prompt.
#                         next non-empty → advance to that node.
#                         next empty     → close the dialog.
#
# node_id must be unique within its DialogData.
# ──────────────────────────────────────────────────────────────────────────────

## Unique identifier for this node within the conversation.
@export var node_id: String = ""

## Text displayed by the typewriter effect.
@export_multiline var text: String = ""

## For linear nodes (no choices): node_id to advance to on confirm.
## Leave empty to close the dialog after this node.
@export var next: String = ""

## For branching nodes: choices presented to the player.
## When non-empty, `next` is ignored.
@export var choices: Array[DialogChoice] = []
