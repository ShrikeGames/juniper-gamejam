extends Node3D
class_name PlayerCamera

@export var look_at_node: Top
@export var target_node: Node3D
@export var ground_mask: int = 2
@export var max_ray_distance: float = 1000.0
@export var launcher_crank:Node3D
@export var top_holder_spot:Node3D
@export var launcher:Node3D
@export var crank_audio_stream_player:AudioStreamPlayer

var rotate_crank:bool = false
var is_launched:bool = false
# 0 top left, 1 top right, 2 bottom right, 3 bottom left
var mouse_circle_state:int = -1
var last_mouse_position:Vector2
var mouse_distance_traveled:float = 0.0
var last_mouse_circle_state:int = -1
var mouse_states_visited:Array = []
@export var computer_tops:Array[Node3D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotate_crank = false
	is_launched = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if look_at_node and is_launched:
		self.look_at(look_at_node.global_position)
	if rotate_crank or not look_at_node.launched:
		look_at_node.global_position = top_holder_spot.global_position
		look_at_node.linear_velocity = Vector3.ZERO
		look_at_node.angular_velocity = Vector3.ZERO
	if rotate_crank:
		crank_audio_stream_player.pitch_scale = randf_range(0.5, 1.5)
		crank_audio_stream_player.play()
		var distance_bonus:float = min(5.0, max(0.0, mouse_distance_traveled * 0.001))
		launcher_crank.rotate(Vector3.UP, -distance_bonus*0.1)
	else:
		crank_audio_stream_player.stop()
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if is_launched and event.is_action_pressed("LMB"):
			var cam := get_viewport().get_camera_3d()
			if cam == null or target_node == null:
				return
			var mouse_pos: Vector2 = event.position
			var from: Vector3 = cam.project_ray_origin(mouse_pos)
			var dir: Vector3 = cam.project_ray_normal(mouse_pos)
			var to: Vector3 = from + dir * max_ray_distance
			var space_state := get_world_3d().direct_space_state
			var query := PhysicsRayQueryParameters3D.create(from, to)
			query.collision_mask = ground_mask
			var hit := space_state.intersect_ray(query)
			if hit and hit.has("position"):
				target_node.global_position = hit["position"]
				self.look_at_node.impulse_to_target()
		else:
			# hold LMB and spin mouse to spin the crank
			if event.is_action_pressed("LMB") and event.pressed:
				rotate_crank = true
			if event.is_action_released("LMB"):
				# and increase launch power
				# release LMB to release the top
				# apply force to top based on power
				rotate_crank = false
				look_at_node.launched = true
				var distance_bonus:float = min(5.0, max(0.0, mouse_distance_traveled * 0.001))
				look_at_node.move_speed += distance_bonus
				look_at_node.right_speed += distance_bonus
				look_at_node.spin_speed += distance_bonus
				launcher.visible = false
				is_launched = true
				mouse_distance_traveled = 0.0
				for computer in computer_tops:
					computer.launched = true
				
				
	elif event is InputEventMouseMotion and rotate_crank:
		if last_mouse_position or last_mouse_position == Vector2.ZERO and last_mouse_circle_state >= 0:
			var diff:Vector2 = event.global_position - last_mouse_position
			if diff.x >= 0 and diff.y <= 0 and last_mouse_circle_state in [-1, 3, 0]:
				mouse_circle_state = 0
			elif diff.x >= 0 and diff.y >= 0 and last_mouse_circle_state in [-1, 0, 1]:
				mouse_circle_state = 1
			elif diff.x <= 0 and diff.y >= 0 and last_mouse_circle_state in [-1, 1, 2]:
				mouse_circle_state = 2
			elif diff.x <= 0 and diff.y <= 0 and last_mouse_circle_state in [-1, 2, 3]:
				mouse_circle_state = 3
			if mouse_circle_state not in mouse_states_visited:
				mouse_states_visited.append(mouse_circle_state)
				mouse_distance_traveled += abs(diff.length())
			
			
			if len(mouse_states_visited) >= 4:
				mouse_circle_state = -1
				last_mouse_position = Vector2.ZERO
				last_mouse_circle_state = -1
				mouse_states_visited = []
				return
		last_mouse_circle_state = mouse_circle_state
		last_mouse_position = event.global_position
		
