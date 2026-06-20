extends Node3D

@export var tops:Array[Top] = []
@export var scene_to_change_to:String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO generate the computer players
	# place them in the tree
	# do a countdown
	# display the instructions for cranking the launcher
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dead_tops:int = 0
	for top in tops:
		if top.spin_speed > 0:
			return
		dead_tops +=1
	if dead_tops >= len(tops) - 1:
		get_tree().change_scene_to_file(scene_to_change_to)
