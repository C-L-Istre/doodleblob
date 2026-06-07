extends Node2D

# ──────────────────────────────────────────────────────────────────────────────
# Level
#
# Attach to each level's root node. Replaces any inline "extends Node2D" script
# that was previously embedded in the .tscn.
#
# Quest registration rule:
#   Register on a level if it contains quest content — an NPC that starts or
#   advances the quest, or a level exit that checks all_complete(). Skip levels
#   that are pure traversal with no quest interaction.
#
#   The QuestManager autoload carries state between levels automatically, so
#   re-registering on a later level is a no-op for a normal playthrough.
#   It matters for level select: if the player jumps straight to level 3,
#   registering there ensures all_complete() returns false because the quest
#   is INACTIVE — not because the registry is empty.
#
# Inspector setup per level:
#   Level 1 — drag find_the_king.tres into the quests array  (quest giver here)
#   Level 2 — leave quests empty                             (no quest content)
#   Level 3 — drag find_the_king.tres into the quests array  (quest target here)
# ──────────────────────────────────────────────────────────────────────────────

## Quests to register when this level loads.
## Drag .tres Quest resources here in the Inspector.
## register() is idempotent — existing progress is never reset on reload.
@export var quests: Array[Quest] = []


func _ready() -> void:
	for quest in quests:
		QuestManager.register(quest)
