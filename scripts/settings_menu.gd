extends Control

class_name SettingsMenu

@onready var bg_music_slider: HSlider = $Panel/VBoxContainer/BgMusicSlider
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/SfxSlider
@onready var close_button: Button = $Panel/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not AudioServer.bus_count > 1:
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, "Music")
		AudioServer.add_bus(2)
		AudioServer.set_bus_name(2, "SFX")

	var music_bus_idx: int = AudioServer.get_bus_index("Music")
	var sfx_bus_idx: int = AudioServer.get_bus_index("SFX")

	bg_music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_idx))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_idx))
	
	bg_music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	close_button.pressed.connect(_on_close_pressed)

func _on_music_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_sfx_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))

func _on_close_pressed() -> void:
	hide()
