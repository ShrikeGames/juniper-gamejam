extends Node3D
class_name PlayerCamera

@export var look_at_node: Top
@export var target_node: Node3D
@export var ground_mask: int = 2
@export var max_ray_distance: float = 1000.0
@export var launcher_crank:Node3D
@export var top_holder_spot:Node3D
@export var launcher:Node3D
var rotate_crank:bool = false
var is_launched:bool = false

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
		launcher_crank.rotate(Vector3.UP, -0.2)
		
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
				rotate_crank = false
				look_at_node.launched = true
				launcher.visible = false
				is_launched = true
			# and increase launch power
			# release LMB to release the top
			# apply force to top based on power
