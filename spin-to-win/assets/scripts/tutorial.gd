extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.game_state["settings"]["tutorial_complete"] = true
	Global.save_settings()
