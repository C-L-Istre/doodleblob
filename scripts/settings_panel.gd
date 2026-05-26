extends Panel

@onready var main_volume_slider = %MainVolumeSlider
@onready var main_mute_button: CheckButton = %MainMuteButton

@onready var music_volume_slider = %MusicVolumeSlider
@onready var music_mute_button: CheckButton = %MusicMuteButton

@onready var sfx_volume_slider = %SFXVolumeSlider
@onready var sfx_mute_button: CheckButton = %SFXMuteButton

@onready var fullscreen_checkbox = %FullscreenCheckBox
@onready var vsync_check_button: CheckButton = %VsyncCheckButton
@onready var resolution_option_button: OptionButton = %ResolutionOptionButton

@onready var close_button = %CloseSettingsButton

const CONFIG_PATH := "user://settings.cfg"

const BUS_MAIN  := 0
const BUS_MUSIC := 1
const BUS_SFX   := 2

const RESOLUTIONS := [
	Vector2i(1280,  720),
	Vector2i(1600,  900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

var config := ConfigFile.new()

func _ready() -> void:
	# Hide display controls that have no effect outside desktop
	var is_desktop := PlatformDetection.can_quit()
	fullscreen_checkbox.visible      = is_desktop
	vsync_check_button.visible       = is_desktop
	resolution_option_button.visible = is_desktop

	load_settings()
	apply_settings()

func load_settings() -> void:
	var err := config.load(CONFIG_PATH)
	if err != OK:
		print("No existing settings file found. Using defaults.")

func save_settings() -> void:
	config.save(CONFIG_PATH)

func apply_settings() -> void:
	# ── Audio ──────────────────────────────────────────────────────────────────
	var main_vol:    float = config.get_value("audio", "main",         1.0)
	var music_vol:   float = config.get_value("audio", "music",        1.0)
	var sfx_vol:     float = config.get_value("audio", "sfx",          1.0)
	var main_muted:  bool  = config.get_value("audio", "main_muted",   false)
	var music_muted: bool  = config.get_value("audio", "music_muted",  false)
	var sfx_muted:   bool  = config.get_value("audio", "sfx_muted",    false)

	main_volume_slider.value  = main_vol
	music_volume_slider.value = music_vol
	sfx_volume_slider.value   = sfx_vol

	AudioServer.set_bus_volume_db(BUS_MAIN,  linear_to_db(main_vol))
	AudioServer.set_bus_volume_db(BUS_MUSIC, linear_to_db(music_vol))
	AudioServer.set_bus_volume_db(BUS_SFX,   linear_to_db(sfx_vol))

	main_mute_button.button_pressed  = main_muted
	music_mute_button.button_pressed = music_muted
	sfx_mute_button.button_pressed   = sfx_muted

	AudioServer.set_bus_mute(BUS_MAIN,  main_muted)
	AudioServer.set_bus_mute(BUS_MUSIC, music_muted)
	AudioServer.set_bus_mute(BUS_SFX,   sfx_muted)

	# ── Display (desktop only) ─────────────────────────────────────────────────
	if not PlatformDetection.can_quit():
		return

	resolution_option_button.clear()
	for i in range(RESOLUTIONS.size()):
		var res: Vector2i = RESOLUTIONS[i]
		resolution_option_button.add_item("%dx%d" % [res.x, res.y])

	var saved_width:  int = config.get_value("video", "width",  1280)
	var saved_height: int = config.get_value("video", "height",  720)
	var saved_resolution := Vector2i(saved_width, saved_height)

	var selected_index := 0
	for i in range(RESOLUTIONS.size()):
		if RESOLUTIONS[i] == saved_resolution:
			selected_index = i
			break

	resolution_option_button.select(selected_index)

	var fullscreen: bool = config.get_value("video", "fullscreen", false)
	var vsync_enabled: bool = config.get_value("video", "vsync", true)

	fullscreen_checkbox.button_pressed  = fullscreen
	vsync_check_button.button_pressed   = vsync_enabled

	if not fullscreen:
		DisplayServer.window_set_size(saved_resolution)

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED
		if vsync_enabled
		else DisplayServer.VSYNC_DISABLED
	)

# ── Audio signal handlers ──────────────────────────────────────────────────────

func _on_main_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(BUS_MAIN, linear_to_db(value))
	config.set_value("audio", "main", value)
	save_settings()

func _on_main_mute_button_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(BUS_MAIN, toggled_on)
	config.set_value("audio", "main_muted", toggled_on)
	save_settings()

func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(BUS_MUSIC, linear_to_db(value))
	config.set_value("audio", "music", value)
	save_settings()

func _on_music_mute_button_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(BUS_MUSIC, toggled_on)
	config.set_value("audio", "music_muted", toggled_on)
	save_settings()

func _on_sfx_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(BUS_SFX, linear_to_db(value))
	config.set_value("audio", "sfx", value)
	save_settings()

func _on_sfx_mute_button_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(BUS_SFX, toggled_on)
	config.set_value("audio", "sfx_muted", toggled_on)
	save_settings()

# ── Display signal handlers (desktop only) ─────────────────────────────────────

func _on_resolution_option_button_item_selected(index: int) -> void:
	if not PlatformDetection.can_quit():
		return
	var resolution: Vector2i = RESOLUTIONS[index]
	DisplayServer.window_set_size(resolution)
	config.set_value("video", "width",  resolution.x)
	config.set_value("video", "height", resolution.y)
	save_settings()

func _on_fullscreen_check_box_toggled(value: bool) -> void:
	if not PlatformDetection.can_quit():
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if value
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	config.set_value("video", "fullscreen", value)
	save_settings()

func _on_vsync_check_button_toggled(toggled_on: bool) -> void:
	if not PlatformDetection.can_quit():
		return
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED
		if toggled_on
		else DisplayServer.VSYNC_DISABLED
	)
	config.set_value("video", "vsync", toggled_on)
	save_settings()

func _on_close_settings_button_pressed() -> void:
	visible = false
