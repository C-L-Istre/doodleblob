class_name QuestObjective
extends Resource

# ──────────────────────────────────────────────────────────────────────────────
# QuestObjective
#
# One step inside a Quest. Author as elements of Quest.objectives in the
# Inspector or in a saved .tres file.
#
# QuestManager auto-completes the parent quest when every objective's
# current progress reaches required_count.
# ──────────────────────────────────────────────────────────────────────────────

## Unique identifier within the parent Quest. Used in event strings:
##   "advance:quest_id:objective_id"
@export var objective_id: String = ""

## Human-readable description shown in quest log or HUD.
@export var description: String = ""

## How many times this objective must be advanced before it is satisfied.
## Use 1 for talk-to-NPC or reach-location tasks; higher for collection tasks.
@export var required_count: int = 1
