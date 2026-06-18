extends Node

enum UIState {
	GAME,
	MENU,
	TEXT_INPUT
}

var current_state: UIState = UIState.GAME
signal state_changed(new_state: UIState)

func set_state(new_state: UIState) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	state_changed.emit(new_state)

	_apply_state_rules()


# ─────────────────────────────────────────────────────────────
# State queries
# ─────────────────────────────────────────────────────────────

func is_game() -> bool:
	return current_state == UIState.GAME

func is_menu() -> bool:
	return current_state == UIState.MENU

func is_text_input() -> bool:
	return current_state == UIState.TEXT_INPUT


# ─────────────────────────────────────────────────────────────
# Core enforcement layer (THIS is what fixes your bug)
# ─────────────────────────────────────────────────────────────

func _apply_state_rules() -> void:
	match current_state:
		UIState.GAME:
			_release_focus_from_ui()

		UIState.MENU:
			_set_ui_focus_mode(Control.FOCUS_ALL)

		UIState.TEXT_INPUT:
			_lock_ui_focus_except_text_input()


# ─────────────────────────────────────────────────────────────
# Focus rules
# ─────────────────────────────────────────────────────────────

func _release_focus_from_ui() -> void:
	var vp := get_viewport()
	vp.gui_release_focus()


func _set_ui_focus_mode(mode: Control.FocusMode) -> void:
	for n in get_tree().get_nodes_in_group("ui_focus_lockable"):
		if n is Control:
			n.focus_mode = mode


func _lock_ui_focus_except_text_input() -> void:
	# Prevent ALL UI controls except LineEdit from stealing focus
	for n in get_tree().get_nodes_in_group("ui_focus_lockable"):
		if n is Control:
			n.focus_mode = Control.FOCUS_NONE
