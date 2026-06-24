extends Node3D

@export var master_volume_slider:HSlider
@export var music_volume_slider:HSlider
@export var sfx_volume_slider:HSlider
@export var voices_volume_slider:HSlider
@export var ambient_volume_slider:HSlider

func _ready() -> void:
	Global.load_settings()
	master_volume_slider.value = Global.game_state["settings"]["volume"]["master"]
	music_volume_slider.value = Global.game_state["settings"]["volume"]["music"]
	sfx_volume_slider.value = Global.game_state["settings"]["volume"]["sfx"]
	voices_volume_slider.value = Global.game_state["settings"]["volume"]["voices"]
	ambient_volume_slider.value = Global.game_state["settings"]["volume"]["ambient"]

func update_volume(settings_name:String, audio_bus_index: int, linear_value: float):
	var volume_db = 20 * (log(linear_value * 0.01) / log(10))
	AudioServer.set_bus_volume_db(audio_bus_index, volume_db)
	Global.game_state["settings"]["volume"][settings_name] = linear_value
	Global.save_settings()

func _on_master_volume_slider_value_changed(value: float) -> void:
	var audio_bus_index:int = AudioServer.get_bus_index("Master")
	update_volume("master", audio_bus_index, value)

func _on_music_volume_slider_value_changed(value: float) -> void:
	var audio_bus_index:int = AudioServer.get_bus_index("Music")
	update_volume("music", audio_bus_index, value)

func _on_sfx_volume_slider_value_changed(value: float) -> void:
	var audio_bus_index:int = AudioServer.get_bus_index("SFX")
	update_volume("sfx", audio_bus_index, value)

func _on_voices_volume_slider_value_changed(value: float) -> void:
	var audio_bus_index:int = AudioServer.get_bus_index("Voices")
	update_volume("voices", audio_bus_index, value)

func _on_ambient_volume_slider_value_changed(value: float) -> void:
	var audio_bus_index:int = AudioServer.get_bus_index("Ambient")
	update_volume("ambient", audio_bus_index, value)
