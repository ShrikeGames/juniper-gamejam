extends Node3D

@export var num_cpus:int = 3
@export var tops:Array[Top] = []
@export var scene_to_change_to:String
@export var cpu_container:Node3D
@export var target_node:Node3D
@export var target_above_node:Node3D
@export var look_at_node:Node3D

var launcher_resource:Resource = load("res://assets/scenes/launcher.tscn")
var top_resource:Resource = load("res://assets/scenes/top.tscn")

func get_circle_positions(radius: float, y_pos: float = 5.0, segments: int = 24) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var angle_step: float = TAU / segments
	for i in range(segments + 1):
		var angle: float = i * angle_step
		var x: float = radius * cos(angle)
		var z: float = radius * sin(angle)
		positions.append(Vector3(x, y_pos, z))
	return positions

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# generate the computer players
	var random_positions:Array[Vector3] = get_circle_positions(4.0)
	var random_index:int = len(random_positions)-1
	
	for i in range(num_cpus):
		var launcher:Launcher = launcher_resource.instantiate()
		cpu_container.add_child(launcher)
		var cpu_pos:Vector3 = random_positions[random_index]
		launcher.global_position = cpu_pos
		random_index -= randi_range(5, 7)
		launcher.look_at(Vector3(0,5,0))
		
		var cpu_top:Top = top_resource.instantiate()
		cpu_top.target_node = target_node
		cpu_top.target_above_node = target_above_node
		cpu_top.look_at_node = look_at_node
		cpu_top.launcher = launcher
		cpu_top.launched = false
		cpu_top.center_speed = randf_range(10.0, 25.0)
		cpu_top.move_speed = randf_range(10.0, 25.0)
		cpu_top.spin_speed = randf_range(15.0, 25.0)
		cpu_top.right_speed = randf_range(10.0, 25.0)
		cpu_top.mass = randf_range(0.75, 1.5)
		if cpu_top.move_speed > cpu_top.spin_speed and cpu_top.move_speed > cpu_top.right_speed:
			# red speed
			cpu_top.colour = Color(1.0, randf_range(0, 0.5), randf_range(0, 0.5))
		elif cpu_top.spin_speed > cpu_top.move_speed and cpu_top.spin_speed > cpu_top.right_speed:
			# green borpa spin
			cpu_top.colour = Color(randf_range(0, 0.5), 1.0, randf_range(0, 0.5))
		elif cpu_top.right_speed > cpu_top.move_speed and cpu_top.right_speed > cpu_top.spin_speed:
			# blue stability
			cpu_top.colour = Color(randf_range(0, 0.5), randf_range(0, 0.5), 1.0)
		else:
			# even
			var rand_color:float = randf_range(0, 0.5)
			cpu_top.colour = Color(rand_color, rand_color, rand_color)
		cpu_container.add_child(cpu_top)
		
		cpu_top.global_position = launcher.crank_top_spot.global_position
		tops.append(cpu_top)
		
	# place them in the tree
	# do a countdown
	# display the instructions for cranking the launcher
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dead_tops:int = 0
	for top in tops:
		if top.spin_speed <= 0:
			dead_tops +=1
	if dead_tops >= len(tops) - 1:
		get_tree().change_scene_to_file(scene_to_change_to)
