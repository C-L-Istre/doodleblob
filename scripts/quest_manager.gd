extends Node

# ──────────────────────────────────────────────────────────────────────────────
# QuestManager  (autoload)
#
# Tracks quest and objective state for the current play session. State lives
# in memory and persists across scene loads because this is an autoload.
# Call reset() at the start of each new game alongside the other managers.
#
# ── Typical setup ─────────────────────────────────────────────────────────────
#
# 1. Save Quest resources as .tres files (e.g. res://data/quests/find_king.tres)
# 2. In each level's _ready(), register the quests that are relevant:
#
#       QuestManager.register(preload("res://data/quests/find_king.tres"))
#
#    register() is idempotent — calling it again after a level reload does not
#    reset a quest that is already in progress.
#
# 3. Wire event strings into DialogNode.quest_event / DialogChoice.quest_event
#    and condition strings into DialogChoice.condition directly in the Inspector.
#
# ── Event string format ───────────────────────────────────────────────────────
#
#   "start:quest_id"                  — begin an inactive quest
#   "advance:quest_id:objective_id"   — increment an objective (by 1)
#   "complete:quest_id"               — mark quest complete immediately
#   "fail:quest_id"                   — mark quest failed
#
# ── Condition string format ───────────────────────────────────────────────────
#
#   "inactive:quest_id"   — true if the quest has not started yet
#   "active:quest_id"     — true if the quest is in progress
#   "complete:quest_id"   — true if the quest is finished
#   "failed:quest_id"     — true if the quest has failed
#
# ── Win condition ─────────────────────────────────────────────────────────────
#
#   QuestManager.all_complete() returns true when every registered quest is
#   done. Use this in a level exit trigger or the future game_end script.
# ──────────────────────────────────────────────────────────────────────────────

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)
## Emitted each time an objective is advanced, before auto-complete check.
signal objective_advanced(quest_id: String, obj_id: String, current: int, required: int)

enum QuestState { INACTIVE, ACTIVE, COMPLETED, FAILED }

# quest_id → Quest resource
var _registry: Dictionary = {}

# quest_id → { "state": QuestState, "progress": { obj_id: int } }
var _states: Dictionary = {}


# ── Registration ──────────────────────────────────────────────────────────────

## Register a Quest so the manager knows it exists.
## Idempotent — safe to call on every level load; existing progress is kept.
func register(quest: Quest) -> void:
	_registry[quest.quest_id] = quest
	if not _states.has(quest.quest_id):
		_states[quest.quest_id] = {
			"state":    QuestState.INACTIVE,
			"progress": {},
		}


# ── State queries ─────────────────────────────────────────────────────────────

func get_state(quest_id: String) -> QuestState:
	return _states.get(quest_id, { "state": QuestState.INACTIVE })["state"]

func is_inactive(quest_id: String) -> bool:
	return get_state(quest_id) == QuestState.INACTIVE

func is_active(quest_id: String) -> bool:
	return get_state(quest_id) == QuestState.ACTIVE

func is_complete(quest_id: String) -> bool:
	return get_state(quest_id) == QuestState.COMPLETED

func is_failed(quest_id: String) -> bool:
	return get_state(quest_id) == QuestState.FAILED

## Returns the current progress count for a specific objective.
func get_progress(quest_id: String, obj_id: String) -> int:
	if not _states.has(quest_id):
		return 0
	return _states[quest_id]["progress"].get(obj_id, 0)

## Returns true when every registered quest is completed.
## Use this as the win condition for game_end.
func all_complete() -> bool:
	if _registry.is_empty():
		return false
	for id: String in _registry:
		if not is_complete(id):
			return false
	return true


# ── State mutations ───────────────────────────────────────────────────────────

func start_quest(quest_id: String) -> void:
	if not _states.has(quest_id):
		push_warning("QuestManager.start_quest: unknown quest '%s'" % quest_id)
		return
	if not is_inactive(quest_id):
		return  # Already running or finished — silently ignore.
	_states[quest_id]["state"] = QuestState.ACTIVE
	quest_started.emit(quest_id)


func advance_objective(quest_id: String, obj_id: String, amount: int = 1) -> void:
	if not is_active(quest_id):
		return
	var quest: Quest = _registry.get(quest_id)
	if not quest:
		return

	var prog: Dictionary = _states[quest_id]["progress"]
	prog[obj_id] = prog.get(obj_id, 0) + amount

	var required: int = _required_count(quest, obj_id)
	objective_advanced.emit(quest_id, obj_id, prog[obj_id], required)

	if _all_objectives_met(quest):
		complete_quest(quest_id)


func complete_quest(quest_id: String) -> void:
	if not _states.has(quest_id):
		push_warning("QuestManager.complete_quest: unknown quest '%s'" % quest_id)
		return
	_states[quest_id]["state"] = QuestState.COMPLETED
	quest_completed.emit(quest_id)


func fail_quest(quest_id: String) -> void:
	if not _states.has(quest_id):
		push_warning("QuestManager.fail_quest: unknown quest '%s'" % quest_id)
		return
	_states[quest_id]["state"] = QuestState.FAILED
	quest_failed.emit(quest_id)


## Reset all quest state to INACTIVE with zero progress.
## Call at the start of a new game alongside ScoreManager.reset_score()
## and HealthManager.reset_game().
func reset() -> void:
	for id: String in _states:
		_states[id] = {
			"state":    QuestState.INACTIVE,
			"progress": {},
		}


# ── Dialog integration ────────────────────────────────────────────────────────

## Parse and execute an event string authored on a DialogNode or DialogChoice.
## Called automatically by DialogBox — no manual wiring needed.
func fire_event(event: String) -> void:
	if event.is_empty():
		return
	var parts: PackedStringArray = event.split(":")
	if parts.size() < 2:
		push_warning("QuestManager.fire_event: malformed event '%s'" % event)
		return
	match parts[0]:
		"start":
			start_quest(parts[1])
		"advance":
			if parts.size() < 3:
				push_warning("QuestManager.fire_event: 'advance' needs quest_id:objective_id, got '%s'" % event)
				return
			advance_objective(parts[1], parts[2])
		"complete":
			complete_quest(parts[1])
		"fail":
			fail_quest(parts[1])
		_:
			push_warning("QuestManager.fire_event: unknown action '%s' in '%s'" % [parts[0], event])


## Evaluate a condition string authored on a DialogChoice.
## Returns true if the condition passes. An empty string always passes.
## Called automatically by DialogBox — no manual wiring needed.
func check_condition(condition: String) -> bool:
	if condition.is_empty():
		return true
	var parts: PackedStringArray = condition.split(":")
	if parts.size() < 2:
		push_warning("QuestManager.check_condition: malformed condition '%s'" % condition)
		return true
	match parts[0]:
		"inactive":  return is_inactive(parts[1])
		"active":    return is_active(parts[1])
		"complete":  return is_complete(parts[1])
		"failed":    return is_failed(parts[1])
		_:
			push_warning("QuestManager.check_condition: unknown type '%s' in '%s'" % [parts[0], condition])
			return true


# ── Private ───────────────────────────────────────────────────────────────────

func _required_count(quest: Quest, obj_id: String) -> int:
	for obj: QuestObjective in quest.objectives:
		if obj.objective_id == obj_id:
			return obj.required_count
	return 1


func _all_objectives_met(quest: Quest) -> bool:
	if quest.objectives.is_empty():
		return false  # No objectives = must be completed explicitly.
	var prog: Dictionary = _states[quest.quest_id]["progress"]
	for obj: QuestObjective in quest.objectives:
		if prog.get(obj.objective_id, 0) < obj.required_count:
			return false
	return true
