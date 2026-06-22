extends Button
class_name ChallengeButton
@export var scene_to_change_to:String
@export var object_to_show:Container
@export var objects_to_hide:Array[Container]
@export var audio_stream_player:AudioStreamPlayer

var num_cpus:int
var arena_id:int
var rewards_text:String
var rewards:Dictionary
func _ready() -> void:
	var audio_stream_player_stream = preload("res://assets/sound/ui/ui_button_sounds.tres")
	audio_stream_player.stream = audio_stream_player_stream
	audio_stream_player.play()
	
	# number of cpus
	num_cpus = randi_range(1,3)
	# arena
	arena_id = randi_range(0, len(Global.arena_names)-1)
	# reward
	var num_wins = Global.game_state["stats"]["wins"]
	var difficulty_modifier:int = max(1, num_wins/2)
	var possible_stats_to_increase:Array[String] = ["Dexterity", "Power", "Special"]
	var increase_stat:String = possible_stats_to_increase.pick_random()
	var index_to_remove:int = possible_stats_to_increase.find(increase_stat)
	possible_stats_to_increase.remove_at(index_to_remove)
	var decrease_stat:String = possible_stats_to_increase.pick_random()
	
	rewards = {
		
	}
	var positive_diff:int = randi_range(1, difficulty_modifier)
	var negative_diff:int = randi_range(1, difficulty_modifier)
	
	rewards["increase"] = {
		"name": increase_stat,
		"value": positive_diff
	}
	rewards["decrease"] = {
		"name": decrease_stat,
		"value": negative_diff
	}
	rewards_text = "%s +%d\n%s -%d"%[increase_stat, positive_diff, decrease_stat, negative_diff]
	rewards["rewards_text"] = rewards_text
	
	var type_text:String = ""
	if num_cpus <= 1:
		type_text = "1v1 Duel"
	else:
		type_text = "%d-Way FFA"%[num_cpus+1]
	var arena_name:String = Global.arena_names[arena_id]
	
	self.text = "%s\n%s\n%s"%[type_text, arena_name, rewards_text]

func _on_pressed() -> void:
	# update Global.gamestate object
	Global.game_state["next_match"]["num_cpus"] = num_cpus
	Global.game_state["next_match"]["arena_id"] = arena_id
	Global.game_state["next_match"]["rewards"] = rewards
	var increase_stat:String = rewards["increase"]["name"]
	var increase_value:int = rewards["increase"]["value"]
	var decrease_stat:String = rewards["decrease"]["name"]
	var decrease_value:int = rewards["decrease"]["value"]
	
	if increase_stat == "Dexterity":
		Global.game_state["stats"]["Dexterity"] = modify_stat("Dexterity", increase_value)
	elif increase_stat == "Power":
		Global.game_state["stats"]["Power"] = modify_stat("Power", increase_value)
	elif increase_stat == "Special":
		Global.game_state["stats"]["Special"] = modify_stat("Special", increase_value)
	
	if decrease_stat == "Dexterity":
		Global.game_state["stats"]["Dexterity"] = modify_stat("Dexterity", -decrease_value)
	elif decrease_stat == "Power":
		Global.game_state["stats"]["Power"] = modify_stat("Power", -decrease_value)
	elif decrease_stat == "Special":
		Global.game_state["stats"]["Special"] = modify_stat("Special", -decrease_value)
	
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

func modify_stat(stat_name:String, value:int):
	return min(5, max(1, Global.game_state["stats"][stat_name]+value))

func _on_mouse_entered() -> void:
	var playback = self.audio_stream_player.get_stream_playback() as AudioStreamPlaybackInteractive
	self.audio_stream_player.pitch_scale = randf_range(0.5, 1.5)
	playback.switch_to_clip_by_name("Hover")
