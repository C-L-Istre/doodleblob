class_name Quest
extends Resource

# ──────────────────────────────────────────────────────────────────────────────
# Quest
#
# Data class for a single quest. Save as a .tres file and register it with
# QuestManager.register() at the start of the level that introduces it.
#
# QuestManager auto-completes a quest when all of its objectives are met.
# To bypass objective tracking (e.g. a simple talk-quest with no steps),
# leave objectives empty and call QuestManager.complete_quest() directly from
# a dialog node event: "complete:quest_id".
# ──────────────────────────────────────────────────────────────────────────────

## Unique identifier. Used in all event/condition strings.
@export var quest_id: String = ""

## Short title shown in HUD notifications.
@export var title: String = ""

## Longer description shown in a quest log.
@export_multiline var description: String = ""

## Objectives that must all be satisfied to auto-complete this quest.
## Leave empty for quests driven entirely by explicit "complete:" events.
@export var objectives: Array[QuestObjective] = []
