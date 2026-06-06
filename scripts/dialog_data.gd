class_name DialogData
extends Resource

# ──────────────────────────────────────────────────────────────────────────────
# DialogData
#
# A Resource that carries everything a conversation needs. Using a Resource
# means contributors can author conversations as .tres files in the editor
# and drag them onto NPC nodes — no code required.
#
# Extend this class when you need more fields (portrait, voice, emotion,
# quest_id). Because every call site passes a DialogData, adding a field
# with a default value is non-breaking — no NPC's interact() needs to change.
# ──────────────────────────────────────────────────────────────────────────────

## The name shown above the dialog box. Usually the NPC's name.
@export var speaker: String = ""

## Lines of dialog shown one at a time. The player advances with the interact
## action or a UI button. An empty array is valid — the dialog box won't open.
@export_multiline var lines: Array[String] = []

## Portrait texture shown beside the speaker name.
## Leave null until portrait art is ready — the dialog box hides the portrait
## slot automatically when this is not set.
@export var portrait: Texture2D = null

# ── Reserved for future use ───────────────────────────────────────────────────
# These fields are intentionally left as comments until implemented.
# Adding them now would clutter the Inspector without providing any value.
#
# @export var emotion: String = "neutral"   # drives NPC facial animation
# @export var voice: AudioStream = null     # per-line voice clip
# @export var quest_id: String = ""         # triggers quest state on close
