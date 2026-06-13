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

	var channel := str(cfg.get_value("channel", "name", "dev"))

	text = "v%d.%d.%d" % [major, minor, patch]

	if channel != "release":
		text += "-%s" % channel
