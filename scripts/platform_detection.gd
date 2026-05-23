extends Node

enum PlatformType {
	DESKTOP,
	WEB,
	MOBILE
}

func get_platform() -> PlatformType:
	var os := OS.get_name()

	match os:
		"Windows", "Linux", "macOS":
			return PlatformType.DESKTOP
		"Android", "iOS":
			return PlatformType.MOBILE
		_:
			return PlatformType.WEB

func can_quit() -> bool:
	return get_platform() == PlatformType.DESKTOP

func exit_game() -> void:
	match get_platform():
		PlatformType.DESKTOP:
			get_tree().quit()

		PlatformType.WEB:
			# Cannot close tab → fallback behavior
			print("Web build: Sorry you hate our game but I can't close the tab for you :(")

		PlatformType.MOBILE:
			# Usually ignored or discouraged
			print("Mobile build: Sorry you hate our game but I'm not allowed to close the app for you :(")
