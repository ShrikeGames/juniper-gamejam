extends Node3D

@export var player_top:Top


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_top.update_based_on_stats(Global.game_state["stats"])
	player_top.stamina_progress_bar.visible = false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
