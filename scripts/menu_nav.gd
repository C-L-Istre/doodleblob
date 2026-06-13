class_name MenuNav

# ──────────────────────────────────────────────────────────────────────────────
# MenuNav
#
# Lightweight utility for keyboard/gamepad-navigable menus.
#
# Godot's built-in focus system already moves focus between Controls with
# ui_up / ui_down and fires Button.pressed on ui_accept — we just need to
# ensure the right button is focused on entry and that the focus visual matches
# the hover highlight the player already sees with a mouse.
#
# Usage — call setup() once from a menu's _ready() or show callback:
#
#   MenuNav.setup([%PlayButton, %MainMenuButton, %ExitButton])
#
# For menus that start hidden and are shown later (e.g. PauseMenu), split the
# two responsibilities so styles are wired in _ready() and focus is grabbed
# when the menu actually becomes visible:
#
#   func _ready() -> void:
#       MenuNav.style([%ResumeButton, %SettingsButton, %MainMenuButton, %ExitButton])
#
#   func _show_menu() -> void:
#       MenuNav.focus_first([%ResumeButton, %SettingsButton, %MainMenuButton, %ExitButton])
# ──────────────────────────────────────────────────────────────────────────────


## Wire hover-matching focus styles AND grab initial focus.
## Use for menus that are visible from _ready().
static func setup(buttons: Array[Button]) -> void:
	style(buttons)
	focus_first(buttons)


## Copy each button's hover StyleBox onto its focus slot.
## Makes the keyboard cursor look identical to the mouse hover highlight.
## Safe to call on hidden menus — does not require the node to be visible.
static func style(buttons: Array[Button]) -> void:
	for btn: Button in buttons:
		var hover: StyleBox = btn.get_theme_stylebox("hover")
		if hover:
			btn.add_theme_stylebox_override("focus", hover)


## Grab focus on the first visible, non-disabled button in the list.
## Call this when (re-)showing a menu whose styles are already configured.
static func focus_first(buttons: Array[Button]) -> void:
	for btn: Button in buttons:
		if btn.visible and not btn.disabled:
			btn.grab_focus()
			return
