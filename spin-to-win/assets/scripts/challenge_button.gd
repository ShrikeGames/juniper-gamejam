extends TextureButton
class_name ChallengeButton
@export var scene_to_change_to:String
@export var object_to_show:Container
@export var objects_to_hide:Array[Container]
@export var audio_stream_player:AudioStreamPlayer
@export var richtext:RichTextLabel
@export var preview_image:Sprite2D
@export var top:Top
@export var panel_card:TopPanelCard

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
	var image_path:String = "res://assets/art/ui/arena_previews/arena_preview%d.jpg"%[arena_id]
	var texture = load(image_path)
	self.preview_image.texture = texture
	
	# reward
	var num_wins = Global.game_state["stats"]["wins"]
	var difficulty_modifier:int = max(1, num_wins/2)
	var possible_stats_to_increase:Array[String] = ["Dexterity", "Power", "Special", "Ult"]
	var increase_stat:String = possible_stats_to_increase.pick_random()
	var index_to_remove:int = possible_stats_to_increase.find(increase_stat)
	possible_stats_to_increase.remove_at(index_to_remove)
	if increase_stat != "Ult":
		possible_stats_to_increase.remove_at(possible_stats_to_increase.find("Ult"))
	var decrease_stat:String = possible_stats_to_increase.pick_random()
	
	rewards = {
		
	}
	var positive_diff:int = randi_range(1, difficulty_modifier)
	var negative_diff:int = randi_range(1, difficulty_modifier)
	if increase_stat == "Ult":
		decrease_stat = "Ult"
		positive_diff = randi_range(0, len(Global.ult_names)-1)
		if positive_diff == Global.game_state["stats"]["Ult"]:
			positive_diff = wrapi(positive_diff+1, 0, len(Global.ult_names)-1)
		negative_diff = Global.game_state["stats"]["Ult"]
	
	rewards["increase"] = {
		"name": increase_stat,
		"value": positive_diff
	}
	rewards["decrease"] = {
		"name": decrease_stat,
		"value": negative_diff
	}
	var increase_colour:String = "red"
	if increase_stat == "Dexterity":
		increase_colour = "green"
	elif increase_stat == "Power":
		increase_colour = "red"
	elif increase_stat == "Special":
		increase_colour = "blue"
	else:
		increase_colour = "orange"
	var decrease_colour:String = "red"
	if decrease_stat == "Dexterity":
		decrease_colour = "green"
	elif decrease_stat == "Power":
		decrease_colour = "red"
	elif decrease_stat == "Special":
		decrease_colour = "blue"
	else:
		decrease_colour = "orange"
	
	var positive_stars:String = calculate_stars_string(increase_stat, positive_diff)
	var negative_stars:String = calculate_stars_string(decrease_stat, negative_diff)
	rewards_text = "[color=%s]%s +%s[/color]\n[color=%s]%s -%s[/color]"%[increase_colour, increase_stat, positive_stars, decrease_colour, decrease_stat, negative_stars]
	rewards["rewards_text"] = rewards_text
	
	var type_text:String = ""
	if num_cpus <= 1:
		type_text = "1v1 Duel"
	else:
		type_text = "%d-Way FFA"%[num_cpus+1]
	var arena_name:String = Global.arena_names[arena_id]
	
	self.richtext.text = "[center][color=black]%s\n%s[/color]\n%s"%[type_text, arena_name, rewards_text]

func calculate_stars_string(stat_name:String, num_stars:int):
	if stat_name == "Ult":
		return Global.ult_names[num_stars]
	var top_stars:String = ""
	for i in range(num_stars):
		top_stars += "★"
	return top_stars

func _on_pressed() -> void:
	# update Global.gamestate object
	Global.game_state["next_match"]["num_cpus"] = num_cpus
	Global.game_state["next_match"]["arena_id"] = arena_id
	Global.game_state["next_match"]["rewards"] = rewards
	
	var new_stats:Dictionary = calculate_new_stats()
	
	Global.game_state["stats"] = new_stats.duplicate(true)
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

func calculate_new_stats() -> Dictionary:
	var increase_stat:String = rewards["increase"]["name"]
	var increase_value:int = rewards["increase"]["value"]
	var decrease_stat:String = rewards["decrease"]["name"]
	var decrease_value:int = rewards["decrease"]["value"]
	
	var new_stats:Dictionary = Global.game_state["stats"].duplicate(true)
	if increase_stat == "Dexterity":
		new_stats["Dexterity"] = modify_stat("Dexterity", increase_value)
	elif increase_stat == "Power":
		new_stats["Power"] = modify_stat("Power", increase_value)
	elif increase_stat == "Special":
		new_stats["Special"] = modify_stat("Special", increase_value)
	elif increase_stat == "Ult":
		new_stats["Ult"] = increase_value
	
	if decrease_stat == "Dexterity":
		new_stats["Dexterity"] = modify_stat("Dexterity", -decrease_value)
	elif decrease_stat == "Power":
		new_stats["Power"] = modify_stat("Power", -decrease_value)
	elif decrease_stat == "Special":
		new_stats["Special"] = modify_stat("Special", -decrease_value)
	
	return new_stats

func modify_stat(stat_name:String, value:int):
	return min(5, max(1, Global.game_state["stats"][stat_name]+value))

func _on_mouse_entered() -> void:
	var playback = self.audio_stream_player.get_stream_playback() as AudioStreamPlaybackInteractive
	self.audio_stream_player.pitch_scale = randf_range(0.5, 1.5)
	playback.switch_to_clip_by_name("Hover")
	var new_stats:Dictionary = calculate_new_stats()
	print(new_stats)
	top.update_based_on_stats(new_stats)
	panel_card.update(Global.game_state["stats"])
	


func _on_mouse_exited() -> void:
	top.update_based_on_stats(Global.game_state["stats"])
	panel_card.update(Global.game_state["stats"])
