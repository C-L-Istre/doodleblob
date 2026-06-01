extends Node

# ──────────────────────────────────────────────────────────────────────────────
# PlatformDetection  (autoload)
#
# Detects the current runtime platform. Used by UI scripts to conditionally
# show or hide controls that only make sense on desktop (exit button,
# resolution/fullscreen/vsync settings).
# ──────────────────────────────────────────────────────────────────────────────

enum PlatformType {
	DESKTOP,
	WEB,
	MOBILE,
}

func get_platform() -> PlatformType:
	match OS.get_name():
		"Windows", "Linux", "macOS":
			return PlatformType.DESKTOP
		"Android", "iOS":
			return PlatformType.MOBILE
		_:
			return PlatformType.WEB

func has_touch() -> bool:
	match get_platform():
		PlatformType.MOBILE:
			return true

		PlatformType.WEB:
			return DisplayServer.is_touchscreen_available()

		PlatformType.DESKTOP:
			return false

	return false

## Returns true only on desktop platforms. Use this to gate exit buttons,
## resolution controls, and other desktop-only UI.
func can_quit() -> bool:
	return get_platform() == PlatformType.DESKTOP


## Platform-aware quit. No-op on web and mobile — on those platforms the OS
## controls the app lifecycle, not the game.
func exit_game() -> void:
	match get_platform():
		PlatformType.DESKTOP:
			get_tree().quit()
		PlatformType.WEB:
			# Browser tabs cannot be closed programmatically.
			pass
		PlatformType.MOBILE:
			# On mobile, quitting is discouraged by platform guidelines.
			pass
