extends Label

@export_file("*.cfg") var version_file := "res://resources/version.cfg"

func _ready() -> void:
	var cfg := ConfigFile.new()

	if cfg.load(version_file) != OK:
		text = "v?.?.?"
		return

	var major := int(cfg.get_value("version", "major", 0))
	var minor := int(cfg.get_value("version", "minor", 0))
	var patch := int(cfg.get_value("version", "patch", 0))

	var commit := str(cfg.get_value("build", "commit", "local"))
	var channel := str(cfg.get_value("channel", "name", "dev"))

	# Base version string
	text = "v%d.%d.%d" % [major, minor, patch]

	# Add channel if not release
	if channel != "release":
		text += "-%s" % channel

	# Add commit ALWAYS (or optionally only non-local builds)
	text += "-%s" % commit
