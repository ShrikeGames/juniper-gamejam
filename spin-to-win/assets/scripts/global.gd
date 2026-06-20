extends Node

class_name GlobalState

var settings_config_location: String = "user://user_settings_v1.json"
var game_state: Dictionary = {
	"settings": {
		"volume": {
			"master": 100.0,
			"music": 10.0,
			"sfx": 100.0,
			"voices": 100.0,
			"ambient": 100.0
		}
	}
}
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
