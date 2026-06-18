extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────
# GameEnd
#
# Combined win/lose screen. Loads after the final level exit or when all lives
# are lost. win_quest_id determines the headline: if the named quest is
# complete the screen reads "Game Won", otherwise "Game Over".
#
# Inspector setup:
#   restart_scene  — level scene to load on Play Again
#   win_quest_id   — quest_id string from find_the_king.tres (or whichever
#                    quest acts as the win condition)
# ──────────────────────────────────────────────────────────────────────────────

## Scene to load when the player clicks Play Again. Set in the Inspector.
@export_file("*.tscn") var restart_scene: String = ""
@export var win_quest_id: String = ""

@onready var win_lose_label: Label = %WinLoseLabel
@onready var exit_button: Button = %ExitButton
@onready var high_score_accept: AcceptDialog = %HighScoreAcceptDialog
@onready var username_line_edit: LineEdit = %UsernameLineEdit

func _ready() -> void:
	exit_button.visible = PlatformDetection.can_quit()
	MenuNav.setup([%PlayButton, %MainMenuButton, %ExitButton])

	##if QuestManager.all_complete():
	if QuestManager.is_complete(win_quest_id):
		win_lose_label.text = "Game Won"
	else:
		win_lose_label.text = "Game Over"
		
	var qualifies := ScoreManager.qualifies_for_leaderboard(
		ScoreManager.current_score
	)
	
	if qualifies:
		high_score_accept.popup_centered()

		await get_tree().process_frame
		await get_tree().process_frame

		UIManager.set_state(UIManager.UIState.TEXT_INPUT)

		call_deferred("_focus_username")

func _input(event: InputEvent) -> void:

	# Stop held navigation from stealing focus immediately
	if event.is_action("ui_right") \
	or event.is_action("ui_left") \
	or event.is_action("ui_up") \
	or event.is_action("ui_down"):

		get_viewport().set_input_as_handled()

func _focus_username() -> void:
	username_line_edit.grab_focus()
	username_line_edit.caret_column = username_line_edit.text.length()

func _submit_leaderboard_score() -> void:
	if ScoreManager.qualifies_for_leaderboard(
		ScoreManager.current_score
	):
		ScoreManager.submit_score(username_line_edit.text)

func _on_username_line_edit_text_submitted(_new_text: String) -> void:
	high_score_accept.hide()
	_submit_leaderboard_score()

	UIManager.set_state(UIManager.UIState.MENU)

func _on_play_button_pressed() -> void:
	_submit_leaderboard_score()
	ScoreManager.finish_level()
	ScoreManager.reset_score()
	HealthManager.reset_game()
	QuestManager.reset()
	get_tree().change_scene_to_file(restart_scene)


func _on_main_menu_button_pressed() -> void:
	_submit_leaderboard_score()
	ScoreManager.finish_level()
	ScoreManager.reset_score()
	HealthManager.reset_game()
	QuestManager.reset()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_exit_button_pressed() -> void:
	_submit_leaderboard_score()
	PlatformDetection.exit_game()
