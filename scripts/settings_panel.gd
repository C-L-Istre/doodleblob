extends Panel

# ──────────────────────────────────────────────────────────────────────────────
# SettingsPanel
#
# Manages audio and display settings. Audio controls (Main / Music / SFX
# volume + mute) work on all platforms. Display controls (resolution,
# fullscreen, vsync) are shown only on desktop and hidden on web/mobile.
#
# Settings are saved to user://settings.cfg immediately on change.
#
# Audio bus indices must match audio/default_bus_layout.tres:
#   0 = Master  |  1 = Music  |  2 = SFX
# ──────────────────────────────────────────────────────────────────────────────

const CONFIG_PATH := "user://settings.cfg"

const BUS_MASTER := 0
const BUS_MUSIC  := 1
const BUS_SFX    := 2

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280,  720),
	Vector2i(1600,  900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

# ── Node references ───────────────────────────────────────────────────────────

@onready var _main_vol_slider:   HSlider      = %MainVolumeSlider
@onready var _main_mute:         CheckButton  = %MainMuteButton

@onready var _music_vol_slider:  HSlider      = %MusicVolumeSlider
@onready var _music_mute:        CheckButton  = %MusicMuteButton

@onready var _sfx_vol_slider:    HSlider      = %SFXVolumeSlider
@onready var _sfx_mute:          CheckButton  = %SFXMuteButton

@onready var _fullscreen_check:  CheckBox     = %FullscreenCheckBox
@onready var _vsync_check:       CheckButton  = %VsyncCheckButton
@onready var _resolution_option: OptionButton = %ResolutionOptionButton
@onready var _resolution_label:  Label        = %ResolutionLabel

var _config := ConfigFile.new()


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	var is_desktop := PlatformDetection.can_quit()
	_fullscreen_check.visible  = is_desktop
	_vsync_check.visible       = is_desktop
	_resolution_option.visible = is_desktop
	_resolution_label.visible  = is_desktop

	_load_settings()
	_apply_settings()


# ── Load / Save ───────────────────────────────────────────────────────────────

func _load_settings() -> void:
	if _config.load(CONFIG_PATH) != OK:
		pass  # No existing file — defaults will be used.


func _save_settings() -> void:
	_config.save(CONFIG_PATH)


# ── Apply ─────────────────────────────────────────────────────────────────────

func _apply_settings() -> void:
	# ── Audio ────────────────────────────────────────────────────────────────
	var main_vol:    float = _config.get_value("audio", "main",         1.0)
	var music_vol:   float = _config.get_value("audio", "music",        1.0)
	var sfx_vol:     float = _config.get_value("audio", "sfx",          1.0)
	var main_muted:  bool  = _config.get_value("audio", "main_muted",   false)
	var music_muted: bool  = _config.get_value("audio", "music_muted",  false)
	var sfx_muted:   bool  = _config.get_value("audio", "sfx_muted",    false)

	_main_vol_slider.value  = main_vol
	_music_vol_slider.value = music_vol
	_sfx_vol_slider.value   = sfx_vol

	AudioServer.set_bus_volume_db(BUS_MASTER, linear_to_db(main_vol))
	AudioServer.set_bus_volume_db(BUS_MUSIC,  linear_to_db(music_vol))
	AudioServer.set_bus_volume_db(BUS_SFX,    linear_to_db(sfx_vol))

	_main_mute.button_pressed  = main_muted
	_music_mute.button_pressed = music_muted
	_sfx_mute.button_pressed   = sfx_muted

	AudioServer.set_bus_mute(BUS_MASTER, main_muted)
	AudioServer.set_bus_mute(BUS_MUSIC,  music_muted)
	AudioServer.set_bus_mute(BUS_SFX,    sfx_muted)

	# ── Display (desktop only) ───────────────────────────────────────────────
	if not PlatformDetection.can_quit():
		return

	_resolution_option.clear()
	for res in RESOLUTIONS:
		_resolution_option.add_item("%dx%d" % [res.x, res.y])

	var saved_w:   int      = _config.get_value("video", "width",      1280)
	var saved_h:   int      = _config.get_value("video", "height",      720)
	var saved_res: Vector2i = Vector2i(saved_w, saved_h)

	var selected_index := 0
	for i in RESOLUTIONS.size():
		if RESOLUTIONS[i] == saved_res:
			selected_index = i
			break
	_resolution_option.select(selected_index)

	var fullscreen:    bool = _config.get_value("video", "fullscreen", false)
	var vsync_enabled: bool = _config.get_value("video", "vsync",       true)

	_fullscreen_check.button_pressed = fullscreen
	_vsync_check.button_pressed      = vsync_enabled

	if not fullscreen:
		DisplayServer.window_set_size(saved_res)

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled
		else DisplayServer.VSYNC_DISABLED
	)


# ── Audio signal handlers ─────────────────────────────────────────────────────

func _on_main_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(BUS_MASTER, linear_to_db(value))
	_config.set_value("audio", "main", value)
	_save_settings()


func _on_main_mute_button_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(BUS_MASTER, toggled_on)
	_config.set_value("audio", "main_muted", toggled_on)
	_save_settings()


func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(BUS_MUSIC, linear_to_db(value))
	_config.set_value("audio", "music", value)
	_save_settings()


func _on_music_mute_button_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(BUS_MUSIC, toggled_on)
	_config.set_value("audio", "music_muted", toggled_on)
	_save_settings()


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(BUS_SFX, linear_to_db(value))
	_config.set_value("audio", "sfx", value)
	_save_settings()


func _on_sfx_mute_button_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(BUS_SFX, toggled_on)
	_config.set_value("audio", "sfx_muted", toggled_on)
	_save_settings()


# ── Display signal handlers (desktop only) ────────────────────────────────────

func _on_resolution_option_button_item_selected(index: int) -> void:
	if not PlatformDetection.can_quit():
		return
	var res: Vector2i = RESOLUTIONS[index]
	DisplayServer.window_set_size(res)
	_config.set_value("video", "width",  res.x)
	_config.set_value("video", "height", res.y)
	_save_settings()


func _on_fullscreen_check_box_toggled(value: bool) -> void:
	if not PlatformDetection.can_quit():
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if value
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	_config.set_value("video", "fullscreen", value)
	_save_settings()


func _on_vsync_check_button_toggled(toggled_on: bool) -> void:
	if not PlatformDetection.can_quit():
		return
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if toggled_on
		else DisplayServer.VSYNC_DISABLED
	)
	_config.set_value("video", "vsync", toggled_on)
	_save_settings()


func _on_close_settings_button_pressed() -> void:
	hide()
