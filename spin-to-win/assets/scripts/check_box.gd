extends CheckBox

@export var settings_name:String
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if settings_name:
		self.button_pressed = Global.game_state["settings"]["gameplay"][settings_name]

func _on_toggled(toggled_on: bool) -> void:
	if settings_name:
		Global.game_state["settings"]["gameplay"][settings_name] = toggled_on
		Global.save_settings()
		if settings_name == "fullscreen":
			Global.toggle_fullscreen()
