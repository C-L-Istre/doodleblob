extends Panel

@onready var main_volume_slider = %MainVolumeSlider
@onready var music_volume_slider = %MusicVolumeSlider
@onready var sfx_volume_slider = %SFXVolumeSlider

@onready var fullscreen_checkbox = %FullscreenCheckBox
@onready var close_button = %CloseSettingsButton

const CONFIG_PATH := "user://settings.cfg"
var config := ConfigFile.new()

func _ready() -> void:
	load_settings()
	apply_settings()

	main_volume_slider.value_changed.connect(_on_main_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)

	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	close_button.pressed.connect(_on_close_pressed)

func load_settings() -> void:
	config.load(CONFIG_PATH)


func save_settings() -> void:
	config.save(CONFIG_PATH)

func apply_settings() -> void:
	var main_vol: float = config.get_value("audio", "main", 1.0)
	var music_vol: float = config.get_value("audio", "music", 1.0)
	var sfx_vol: float = config.get_value("audio", "sfx", 1.0)

	AudioServer.set_bus_volume_db(0, linear_to_db(main_vol))
	AudioServer.set_bus_volume_db(1, linear_to_db(music_vol))
	AudioServer.set_bus_volume_db(2, linear_to_db(sfx_vol))

	main_volume_slider.value = main_vol
	music_volume_slider.value = music_vol
	sfx_volume_slider.value = sfx_vol

	var fullscreen: bool = config.get_value("video", "fullscreen", false)
	fullscreen_checkbox.button_pressed = fullscreen

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)

func _on_main_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
	config.set_value("audio", "main", value)
	save_settings()

func _on_music_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(value))
	config.set_value("audio", "music", value)
	save_settings()

func _on_sfx_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, linear_to_db(value))
	config.set_value("audio", "sfx", value)
	save_settings()

func _on_fullscreen_toggled(value: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if value
		else DisplayServer.WINDOW_MODE_WINDOWED
	)

	config.set_value("video", "fullscreen", value)
	save_settings()

func _on_close_pressed() -> void:
	visible = false
