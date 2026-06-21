extends Node

class_name GlobalState

var settings_config_location: String = "user://user_settings_v1.json"
var arena_names:Array[String] = ["Very Serious Bowl Arena", "Very Serious Spinning Plates Arena"]
var arena_resources:Array[Resource] = [load("res://assets/scenes/arena0.tscn"), load("res://assets/scenes/arena1.tscn")]
var default_game_state: Dictionary = {
	"settings": {
		"volume": {
			"master": 100.0,
			"music": 10.0,
			"sfx": 100.0,
			"voices": 100.0,
			"ambient": 100.0
		}
	},
	"next_match": {
		"num_cpus": 3,
		"arena_id": 0,
		"rewards": {
			"increase": {
				"name": "impulse_speed",
				"value": 2.0
			},
			"decrease": {
				"name": "red",
				"value": -0.5
			},
			"rewards_text": "+2.0 Impulse Speed\n-0.5 Red"
		}
	},
	"stats": {
		"wins": 0,
		"losses": 0,
		"move_speed": 10.0,
		"spin_speed": 10.0,
		"center_speed": 10.0,
		"impulse_speed": 10.0,
		"right_speed": 15.0,
		"mass": 1.0,
		"colour": {
			"r": 0.5,
			"g": 0.5,
			"b": 0.5
		}
	}
}
var game_state: Dictionary = default_game_state.duplicate(true)

func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json_string = FileAccess.get_file_as_string(path)
	var json_dict = JSON.parse_string(json_string)
	
	return json_dict

func load_settings():
	# check if user has settings at settings_config_location
	if not FileAccess.file_exists(settings_config_location):
		save_settings()
	game_state = read_json(settings_config_location)
	

func save_settings():
	# save the results
	var json_string := JSON.stringify(game_state)
	# We will need to open/create a new file for this data string
	var file_access := FileAccess.open(settings_config_location, FileAccess.WRITE)
	if not file_access:
		print("An error happened while saving data: ", FileAccess.get_open_error())
		return
		
	file_access.store_line(json_string)
	file_access.close()
