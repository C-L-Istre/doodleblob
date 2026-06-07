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

@export_group("Quest")
## Quest event fired when the player selects this choice.
## Format: "action:quest_id" or "action:quest_id:objective_id"
## Examples:
##   "start:find_the_king"
##   "advance:find_the_king:accepted_quest"
## Leave empty for no event.
@export var quest_event: String = ""

## Hide this choice unless the condition is met.
## Format: "state:quest_id"
## Examples:
##   "inactive:find_the_king"  — only show before the quest starts
##   "active:find_the_king"    — only show while the quest is in progress
##   "complete:find_the_king"  — only show after the quest is finished
## Leave empty to always show this choice.
@export var condition: String = ""
