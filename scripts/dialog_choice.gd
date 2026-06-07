class_name DialogChoice
extends Resource

# ──────────────────────────────────────────────────────────────────────────────
# DialogChoice
#
# One branch option shown to the player when a DialogNode has multiple paths.
# Author these in the Inspector as elements of a DialogNode's `choices` array.
#
# Leave `next` empty ("") to close the dialog when this choice is picked.
# ──────────────────────────────────────────────────────────────────────────────

## Label displayed on-screen for this choice.
@export var text: String = ""

## node_id of the DialogNode to jump to when this choice is selected.
## Empty string closes the dialog immediately.
@export var next: String = ""
