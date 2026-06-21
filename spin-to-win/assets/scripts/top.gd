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
@export var spin_speed:float = 12.0
@export var right_speed:float = 15.0
@export var move_speed: float = 15.0
@export var center_speed: float = 10.0
@export var impulse_speed: float = 15.0
@export var launched:bool = false
@export var stamina_drain:float = 0.05
@export var force_multiplier:float = 2.0
@export var colour:Color
@export var launcher:Node3D

@export var collision_audio_player:AudioStreamPlayer3D
@export var other_audio_player:AudioStreamPlayer3D

var _last_delta:float

func _ready() -> void:
	var material = StandardMaterial3D.new()
	material.albedo_color = colour
	self.model.material_override = material
	for child in self.model.find_children("test_top", "MeshInstance3D"):
		child.material_override = material
		
	var collision_audio_player_stream = preload("res://assets/sound/top_collision_audio.tres")
	collision_audio_player.stream = collision_audio_player_stream
	collision_audio_player.play()
	var other_audio_player_stream = preload("res://assets/sound/top_other_audio.tres")
	other_audio_player.stream = other_audio_player_stream
	other_audio_player.play()
	

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not launched or spin_speed <= 0:
		return
	var contact_count = state.get_contact_count()
	for i in contact_count:
		var contact_pos:Vector3 = state.get_contact_collider_position(i)
		var collider_object = state.get_contact_collider_object(i)
		self.sparks_particle_emitter.global_position = contact_pos
		self.sparks_particle_emitter.amount = max(1, int(spin_speed)*10.0)
		if is_instance_of(collider_object, Top):
			var speed_force:Vector3 = self.basis.z.normalized()
			var total_force:Vector3 = speed_force * self.force_multiplier
			#self.reduce_stamina(self._last_delta, total_force.length_squared())
			collider_object.reduce_stamina(self._last_delta, total_force.length_squared())
			#self.apply_central_impulse(-total_force)
			collider_object.apply_central_impulse(total_force)
			self.apply_central_impulse(-total_force)
			var random_clank_id:int = randi_range(1,9)
			var clip_name:String = "Clang %d"%random_clank_id
			play_collision_audio_clip(clip_name)
			return
		elif contact_pos.y > self.global_position.y - 0.25:
			self.reduce_stamina(self._last_delta, stamina_drain * 0.25)
			#var random_clank_id:int = randi_range(1,9)
			#var clip_name:String = "Clang %d"%random_clank_id
			#play_collision_audio_clip(clip_name)
			return
		else:
			var random_clank_id:int = randi_range(1,2)
			var clip_name:String = "On Ground %d"%random_clank_id
			play_other_audio_clip(clip_name)
			return
	
func play_collision_audio_clip(clip_name:String):
	#print("Play clip %s"%[clip_name])
	var playback = self.collision_audio_player.get_stream_playback() as AudioStreamPlaybackInteractive
	self.collision_audio_player.pitch_scale = randf_range(0.5, 1.5)
	playback.switch_to_clip_by_name(clip_name)

func play_other_audio_clip(clip_name:String):
	#print("Play clip %s"%[clip_name])
	var playback = self.other_audio_player.get_stream_playback() as AudioStreamPlaybackInteractive
	self.other_audio_player.pitch_scale = randf_range(0.5, 1.5)
	playback.switch_to_clip_by_name(clip_name)

func reduce_stamina(delta: float, drain_amount:float = stamina_drain):
	spin_speed = max(0.0, spin_speed-drain_amount * delta)
	move_speed = max(0.0, move_speed-drain_amount * delta)
	#right_speed = max(5.0, right_speed-drain_amount * delta)
	if spin_speed <= 0:
		move_speed = 0.0
		impulse_speed = 0.0
		right_speed = 0.0
		trail_particle_emitter.emitting = false
		sparks_particle_emitter.emitting = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if spin_speed <= 0:
		return
	self._last_delta = delta
	if not launched:
		self.global_position = launcher.crank_top_spot.global_position
		return
	time += delta
	reduce_stamina(delta)
	if self.global_position.y < -10:
		self.spin_speed = 0.0
	
	if self.get_colliding_bodies().size() > 0 and spin_speed > 0.0:
		self.trail_particle_emitter.emitting = true
		self.sparks_particle_emitter.emitting = true
	else:
		self.trail_particle_emitter.emitting = false
		self.sparks_particle_emitter.emitting = false
		
	#if self.linear_velocity.normalized().length_squared() > 0.01:
		#self.trail_particle_emitter.look_at(self.global_position - self.linear_velocity.normalized(), Vector3.UP)
		#self.trail_particle_emitter.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))
	
func spin_top():
	self.model.global_rotate(self.basis.y, wrapf(spin_speed * 0.1, 0.0, (2*PI)))
	
	
func force_upright_top():
	var correction:Vector3 = self.global_basis.y.cross(Vector3.UP).normalized()
	if correction.length_squared() >= 0.01:
		self.apply_torque(correction * right_speed)
	
func force_lookat_top():
	if self.global_position.y < self.target_above_node.global_position.y:
		self.look_at_node.look_at_from_position(self.global_position, self.target_above_node.global_position)
		self.look_at_node.rotate_object_local(Vector3(1, 0, 0), -PI / 2.0)
	
	var correction:Vector3 = self.global_basis.y.cross(look_at_node.basis.y).normalized()
	if correction.length_squared() >= 0.01:
		self.apply_torque(correction * right_speed)
	
func move_to_center():
	var move_direction:Vector3 = (center_point - self.global_position).normalized()
	#move_direction.y = 0
	self.apply_central_force(move_direction * center_speed)
	
func impulse_to_target():
	if spin_speed <= 0:
		return
	
	var move_direction:Vector3 = (self.target_node.global_position - self.global_position).normalized()
	move_direction.y = 0
	self.linear_velocity = Vector3.ZERO
	self.apply_central_impulse(move_direction * impulse_speed)
	
	
func move_in_current_direction():
	var move_direction:Vector3 = (self.linear_velocity * 0.5).normalized()
	self.apply_central_force(move_direction * move_speed)
	

func _physics_process(_delta: float) -> void:
	if not launched:
		return
	if spin_speed <= 0:
		return
	spin_top()
	#force_upright_top()
	force_lookat_top()
	move_to_center()
	move_in_current_direction()
