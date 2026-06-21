extends Button
class_name RegularButton
@export var scene_to_change_to:String
@export var object_to_show:Container
@export var objects_to_hide:Array[Container]
@export var audio_stream_player:AudioStreamPlayer
@export var wipe_save:bool = false

func _ready() -> void:
	var audio_stream_player_stream = preload("res://assets/sound/ui/ui_button_sounds.tres")
	audio_stream_player.stream = audio_stream_player_stream
	audio_stream_player.play()

func _on_pressed() -> void:
	if wipe_save:
		print("wipe save")
		Global.game_state["stats"] = Global.default_game_state["stats"].duplicate(true)
		Global.game_state["next_match"] = Global.default_game_state["next_match"].duplicate(true)
	Global.save_settings()
	
	if scene_to_change_to:
		get_tree().change_scene_to_file(scene_to_change_to)
	elif object_to_show:
		object_to_show.visible = true
		if objects_to_hide:
			for object_to_hide in objects_to_hide:
				object_to_hide.visible = false
	var playback = self.audio_stream_player.get_stream_playback() as AudioStreamPlaybackInteractive
	self.audio_stream_player.pitch_scale = randf_range(0.5, 1.5)
	playback.switch_to_clip_by_name("Click")

func _on_mouse_entered() -> void:
	var playback = self.audio_stream_player.get_stream_playback() as AudioStreamPlaybackInteractive
	self.audio_stream_player.pitch_scale = randf_range(0.5, 1.5)
	playback.switch_to_clip_by_name("Hover")
