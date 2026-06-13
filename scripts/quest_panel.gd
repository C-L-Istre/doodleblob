extends PanelContainer

@onready var quest_label: Label = %QuestLabel
@onready var objective_label: Label = %ObjectiveLabel

func _ready() -> void:
	QuestManager.quest_started.connect(_refresh)
	QuestManager.quest_completed.connect(_refresh)
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
		var current := QuestManager.get_progress(
			quest.quest_id,
			obj.objective_id
		)

		text += "%s (%d/%d)\n" % [
			obj.description,
			current,
			obj.required_count
		]

	objective_label.text = text


func _on_objective_advanced(
	_quest_id: String,
	_obj_id: String,
	_current: int,
	_required: int
) -> void:
	_refresh()
