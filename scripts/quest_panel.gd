extends PanelContainer

# ──────────────────────────────────────────────────────────────────────────────
# QuestPanel
#
# Pause menu sub-panel showing the first active quest and its objectives.
# Hides itself when no quests are active.
#
# Signal connections are made in code because QuestManager is an autoload
# that does not appear in the editor's connection dialog.
#
# quest_started and quest_completed emit one argument (quest_id: String).
# _refresh() takes none. Callable.unbind(n) drops n arguments before calling,
# so no adapter methods are needed.
# ──────────────────────────────────────────────────────────────────────────────

@onready var quest_label:     Label = %QuestLabel
@onready var objective_label: Label = %ObjectiveLabel


func _ready() -> void:
	QuestManager.quest_started.connect(_refresh.unbind(1))
	QuestManager.quest_completed.connect(_refresh.unbind(1))
	QuestManager.objective_advanced.connect(_on_objective_advanced)
	_refresh()


func _refresh() -> void:
	var active := QuestManager.get_active_quests()

	if active.is_empty():
		hide()
		return

	show()

	var quest: Quest = active[0]
	quest_label.text = quest.title

	var text := ""
	for obj: QuestObjective in quest.objectives:
		var current := QuestManager.get_progress(quest.quest_id, obj.objective_id)
		text += "%s (%d/%d)\n" % [obj.description, current, obj.required_count]
	objective_label.text = text


func _on_objective_advanced(
	_quest_id: String,
	_obj_id: String,
	_current: int,
	_required: int
) -> void:
	_refresh()
