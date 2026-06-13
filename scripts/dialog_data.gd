class_name DialogData
extends Resource

# ──────────────────────────────────────────────────────────────────────────────
# DialogData
#
# Root resource for a branching conversation. Assign to an NPC's dialog_data
# property either inline or as a saved .tres file.
#
# Nodes are stored as an Array so they author cleanly in the Inspector and
# serialize reliably in .tres files. DialogBox builds an internal Dictionary
# at start() for O(1) lookup — order of the array does not matter.
#
# start_node must match the node_id of one entry in `nodes`.
# ──────────────────────────────────────────────────────────────────────────────

## The name shown in the speaker bar above the dialog box.
@export var speaker: String = ""

## Portrait texture shown beside the speaker name.
## Leave null to hide the portrait slot automatically.
@export var portrait: Texture2D = null

## node_id of the first DialogNode to display.
@export var start_node: String = ""

## All nodes in this conversation. Order does not matter.
@export var nodes: Array[DialogNode] = []

# ── Reserved for future use ───────────────────────────────────────────────────
# These fields are intentionally left as comments until implemented.
# Adding them now would clutter the Inspector without providing any value.
#
# @export var emotion: String = "neutral"   # drives NPC facial animation
# @export var voice: AudioStream = null     # per-line voice clip
# @export var quest_id: String = ""         # triggers quest state on close
