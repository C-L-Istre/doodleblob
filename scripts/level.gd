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
#
# Per-level timer:
#   Elapsed time accumulates in _process() from the moment the level loads.
#   level_exit.gd calls record_progress() before changing scenes, which
#   reports this level's time (and score delta) to ScoreManager.total_time /
#   ScoreManager.level_records. If the player dies and the level reloads,
#   the timer restarts from zero for that attempt — only a completed exit
#   is recorded.
#
# Per-level coins:
#   Every node in the "coins" group is counted in _ready() and its
#   `collected` signal connected. When the count collected reaches the
#   total, advance_objective fires for the "collect_all_coins" quest's
#   "all_coins" objective. Coins do not need to be in a group on levels
#   with none — total stays 0 and the objective never fires.
#
#   To award points for a full coin sweep, register a Quest with
#   quest_id = "collect_all_coins", reward_points = 10, and one objective
#   "all_coins" (required_count = 1). Register it on any level that has
#   coins — registration is idempotent, like the find_the_king quest above.
# ──────────────────────────────────────────────────────────────────────────────

## Quests to register when this level loads.
## Drag .tres Quest resources here in the Inspector.
## register() is idempotent — existing progress is never reset on reload.
@export var quests: Array[Quest] = []

## Identifier used as the key in ScoreManager.level_records. Leave empty to
## use the scene file's name (e.g. "level_1") — only set this if you want a
## display name that differs from the filename.
@export var level_id: String = ""

var _elapsed_time:     float = 0.0
var _score_at_start:   int   = 0
var _total_coins:      int   = 0
var _collected_coins:  int   = 0


func _ready() -> void:
	for quest in quests:
		QuestManager.register(quest)

	_score_at_start = ScoreManager.current_score

	var coins := get_tree().get_nodes_in_group("coins")
	_total_coins = coins.size()
	for coin in coins:
		coin.collected.connect(_on_coin_collected)


func _process(delta: float) -> void:
	_elapsed_time += delta


func _on_coin_collected() -> void:
	_collected_coins += 1
	if _total_coins > 0 and _collected_coins >= _total_coins:
		QuestManager.advance_objective("collect_all_coins", "all_coins")


## Report this level's elapsed time and score delta to ScoreManager.
## Called by level_exit.gd before changing scenes on a normal (non-death) exit.
func record_progress() -> void:
	var score_delta: int = ScoreManager.current_score - _score_at_start
	var id: String = level_id
	if id.is_empty():
		id = scene_file_path.get_file().get_basename()
	ScoreManager.record_level(id, _elapsed_time, score_delta)
