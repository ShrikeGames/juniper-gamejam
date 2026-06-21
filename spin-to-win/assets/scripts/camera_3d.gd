extends Node3D
class_name PlayerCamera

@export var player_top: Top
@export var target_node: Node3D
@export var ground_mask: int = 2
@export var max_ray_distance: float = 1000.0
@export var launcher:Launcher
@export var crank_audio_stream_player:AudioStreamPlayer
@export var cpu_container:Node3D

var rotate_crank:bool = false
var is_launched:bool = false
# 0 top left, 1 top right, 2 bottom right, 3 bottom left
var mouse_circle_state:int = -1
var last_mouse_position:Vector2
var mouse_distance_traveled:float = 0.0
var last_mouse_circle_state:int = -1
var mouse_states_visited:Array = []
var cpu_crank_speed:float = 0.1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotate_crank = false
	is_launched = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_top and is_launched:
		self.look_at(player_top.global_position)
	if rotate_crank or not player_top.launched:
		player_top.global_position = launcher.crank_top_spot.global_position
		player_top.linear_velocity = Vector3.ZERO
		player_top.angular_velocity = Vector3.ZERO
	if rotate_crank:
		crank_audio_stream_player.pitch_scale = randf_range(0.5, 1.5)
		crank_audio_stream_player.play()
		var distance_bonus:float = min(5.0, max(0.0, mouse_distance_traveled * 0.001))
		launcher.crank.rotate(Vector3.UP, -distance_bonus*0.1)
		for cpu_launcher in cpu_container.get_children():
			if is_instance_of(cpu_launcher, Launcher):
				cpu_launcher.crank.rotate(Vector3.UP, -cpu_crank_speed)
		cpu_crank_speed += randf_range(0.1, 0.2) * delta
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
				self.player_top.impulse_to_target()
		else:
			# hold LMB and spin mouse to spin the crank
			if event.is_action_pressed("LMB") and event.pressed:
				rotate_crank = true
			if event.is_action_released("LMB"):
				# and increase launch power
				# release LMB to release the top
				# apply force to top based on power
				rotate_crank = false
				player_top.launched = true
				var distance_bonus:float = min(5.0, max(0.0, mouse_distance_traveled * 0.001))
				player_top.move_speed += distance_bonus
				player_top.right_speed += distance_bonus
				player_top.spin_speed += distance_bonus
				launcher.visible = false
				is_launched = true
				mouse_distance_traveled = 0.0
				for cpu in cpu_container.get_children():
					if is_instance_of(cpu, Top):
						cpu.launched = true
					if is_instance_of(cpu, Launcher):
						cpu.visible = false
					
				
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
	else:
		if is_launched and not event.is_action_pressed("LMB"):
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
				self.player_top.target_node.global_position = hit["position"]
