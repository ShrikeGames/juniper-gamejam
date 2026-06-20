extends RigidBody3D
class_name Top

@export var model:MeshInstance3D
@export var trail_particle_emitter:GPUParticles3D
@export var sparks_particle_emitter:GPUParticles3D
@export var target_node:Node3D
var center_point:Vector3 = Vector3.ZERO
@export var target_above_node:Node3D
@export var look_at_node:Node3D
var time:float = 0.0
@export var spin_speed:float = 6.0
@export var right_speed:float = 12.0
@export var move_speed: float = 10.0
var impulse_speed: float = 5.0
@export var launched:bool = false
@export var stamina_drain:float = 0.25

func _ready() -> void:
	pass

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var contact_count = state.get_contact_count()
	for i in contact_count:
		var contact_pos:Vector3 = state.get_contact_collider_position(i)
		self.sparks_particle_emitter.global_position = contact_pos
		self.sparks_particle_emitter.amount = max(0, int(spin_speed)*10.0)
		print("Collision at: ", contact_pos)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not launched:
		return
	time += delta
	spin_speed = max(0.0, spin_speed-stamina_drain * delta)
	move_speed = max(0.0, move_speed-stamina_drain * delta)
	right_speed = max(0.0, right_speed-stamina_drain * delta)
	if spin_speed <= 0:
		move_speed = 0.0
		right_speed = 0.0
	if self.get_colliding_bodies().size() > 0 and spin_speed > 0.0:
		self.trail_particle_emitter.emitting = true
		self.sparks_particle_emitter.emitting = true
	else:
		self.trail_particle_emitter.emitting = false
		self.sparks_particle_emitter.emitting = false
		self.sparks_particle_emitter.position = Vector3(0,0,0)
		
	#if self.linear_velocity.normalized().length_squared() > 0.01:
		#self.trail_particle_emitter.look_at(self.global_position - self.linear_velocity.normalized(), Vector3.UP)
		#self.trail_particle_emitter.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))
	
func spin_top():
	self.model.global_rotate(self.basis.y, wrapf(spin_speed, 0.0, (2*PI)))
	
	
func force_upright_top():
	var correction:Vector3 = self.global_basis.y.cross(Vector3.UP).normalized()
	if correction.length_squared() >= 0.01:
		self.apply_torque(correction * right_speed)
	
func force_lookat_top():
	self.look_at_node.look_at_from_position(self.global_position, self.target_above_node.global_position)
	self.look_at_node.rotate_object_local(Vector3(1, 0, 0), -PI / 2.0)
	
	var correction:Vector3 = self.global_basis.y.cross(look_at_node.basis.y).normalized()
	if correction.length_squared() >= 0.01:
		self.apply_torque(correction * right_speed)
	
func move_to_center():
	var move_direction:Vector3 = (center_point - self.global_position).normalized()
	move_direction.y = 0
	self.apply_central_force(move_direction * move_speed)
	
func impulse_to_target():
	var move_direction:Vector3 = (self.target_node.global_position - self.global_position).normalized()
	move_direction.y = 0
	self.apply_central_impulse(move_direction * impulse_speed)
	
	
func move_in_current_direction():
	var move_direction:Vector3 = (self.linear_velocity * 0.5).normalized()
	self.apply_central_force(move_direction * move_speed)
	

func _physics_process(delta: float) -> void:
	if not launched:
		return
	if spin_speed <= 0:
		return
	spin_top()
	#force_upright_top()
	force_lookat_top()
	move_to_center()
	move_in_current_direction()
