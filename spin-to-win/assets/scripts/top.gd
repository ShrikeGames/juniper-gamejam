extends RigidBody3D
class_name Top

@export var top_name:String = "Top"
@export var model:MeshInstance3D
@export var trail_particle_emitter:GPUParticles3D
@export var sparks_particle_emitter:GPUParticles3D
@export var target_node:Node3D
@export var center_point:Vector3 = Vector3.ZERO
@export var target_above_node:Node3D
@export var look_at_node:Node3D
var time:float = 0.0

@export var spin_speed:float = 10.0
@export var right_speed:float = 15.0
@export var move_speed: float = 20.0
@export var center_speed: float = 10.0
@export var impulse_speed: float = 10.0
@export var launched:bool = false
@export var force_multiplier:float = 1.0
@export var colour:Color = Color(0,0,0)
@export var launcher:Node3D
@export var outline_mesh:MeshInstance3D
var announcer_audio_stream_player:AudioStreamPlayer

@export var collision_audio_player:AudioStreamPlayer3D
@export var other_audio_player:AudioStreamPlayer3D
@export var ai_controlled:bool = false
@export var stamina_progress_bar:TextureProgressBar

var knockout_sprite_animation:AnimatedSprite2D
var ringout_sprite_animation:AnimatedSprite2D

var personal_above_point:Vector3
var last_top_hit:Top
var rocket_dash_available:bool = true

var _last_delta:float
var reset_dash_timer:float
var current_stats:Dictionary

var stamina:float = 3.0
var max_stamina:float = 3.0

func _ready() -> void:
	personal_above_point = self.target_above_node.global_position
	rocket_dash_available = true
	reset_dash_timer = 0
	
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
	
func update_based_on_stats(stats:Dictionary):
	self.current_stats = stats
	var human_bonus:float = 1.5
	if ai_controlled:
		human_bonus = 1.0
	# "Dexterity": 2, # +move speed, +spin speed, -weight, +green
	# "Power": 2, # +force, +weight, (+right speed), +red
	# "Special": 2, # +rocket dash, +force, +ult, +blue
	# "Ult": 0, # id for ultimate ability
	self.move_speed += stats["Dexterity"] * human_bonus
	self.spin_speed += stats["Dexterity"] * 3.0 * human_bonus
	self.mass -= stats["Dexterity"] * 0.1 * human_bonus
	self.colour.g = (stats["Dexterity"]-1) * 0.2 * human_bonus
	
	self.force_multiplier += stats["Power"] * human_bonus
	self.mass += stats["Power"] * 0.1 * human_bonus
	self.right_speed += stats["Power"] * 3.0 * human_bonus
	self.colour.r = (stats["Power"]-1) * 0.2 * human_bonus
	
	self.impulse_speed += stats["Special"] * human_bonus
	self.force_multiplier += stats["Special"] * 0.5 * human_bonus
	# TODO, ult power
	self.colour.b = (stats["Special"]-1) * 0.2 * human_bonus
	
	self.max_stamina = ((stats["Dexterity"]*2.0) + stats["Power"] + (stats["Special"]*0.5)) * 10.0  * human_bonus
	self.stamina = self.max_stamina
	self.stamina_progress_bar.max_value = self.max_stamina
	self.stamina_progress_bar.value = self.stamina
	
	print(stats, ": ", self.colour)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not launched or is_dead():
		return
	var contact_count = state.get_contact_count()
	for i in contact_count:
		var contact_pos:Vector3 = state.get_contact_collider_position(i)
		var collider_object = state.get_contact_collider_object(i)
		self.sparks_particle_emitter.global_position = contact_pos
		self.sparks_particle_emitter.amount = max(1, int(spin_speed)*10.0)
		var collision_normal:Vector3 = state.get_contact_local_normal(i)
		personal_above_point = self.global_position + (collision_normal.normalized() * 4.0)
		# hitting the table outside of the arena insta-kills you
		if is_instance_of(collider_object, Table):
			self.spin_speed = 0
			if ai_controlled:
				self.ringout_sprite_animation.frame = 0
				self.ringout_sprite_animation.visible = true
				self.ringout_sprite_animation.play()
				var playback = self.announcer_audio_stream_player.get_stream_playback() as AudioStreamPlaybackInteractive
				playback.switch_to_clip_by_name("Ringout")
			return
		elif is_instance_of(collider_object, StaticBody3D):
			self.rocket_dash_available = true
		
		if is_instance_of(collider_object, Top):
			var speed_force:Vector3 = self.linear_velocity.normalized()
			var angular_force:Vector3 = self.angular_velocity.normalized()
			
			var total_force:Vector3 = (speed_force + angular_force).normalized() * self.force_multiplier
			var stamina_drain:float = max(1, self.current_stats["Power"] - collider_object.current_stats["Power"])
			if not collider_object.is_dead():
				collider_object.reduce_stamina(stamina_drain)
			collider_object.apply_central_impulse(total_force)
			self.apply_central_impulse(-total_force)
			
			var random_clank_id:int = randi_range(1,9)
			var clip_name:String = "Clang %d"%random_clank_id
			play_collision_audio_clip(clip_name)
			last_top_hit = collider_object
			return
		if contact_pos.y <= self.global_position.y - 0.25:
			var random_clank_id:int = randi_range(1,2)
			var clip_name:String = "On Ground %d"%random_clank_id
			play_other_audio_clip(clip_name)
			var stamina_drain:float = 0.1
			self.reduce_stamina(stamina_drain)
			return
		else:
			var stamina_drain:float = 0.01
			self.reduce_stamina(stamina_drain)
			var random_clank_id:int = randi_range(1,9)
			var clip_name:String = "Clang %d"%random_clank_id
			play_collision_audio_clip(clip_name)
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

func reduce_stamina(drain_amount:float = 0.1):
	self.stamina = max(0.0, self.stamina-drain_amount)
	self.stamina_progress_bar.value = self.stamina
	if is_dead():
		move_speed = 0.0
		impulse_speed = 0.0
		right_speed = 0.0
		spin_speed = 0.0
		trail_particle_emitter.emitting = false
		sparks_particle_emitter.emitting = false
		rocket_dash_available = false
		if ai_controlled:
			self.knockout_sprite_animation.frame = 0
			self.knockout_sprite_animation.visible = true
			self.knockout_sprite_animation.play()
			var playback = self.announcer_audio_stream_player.get_stream_playback() as AudioStreamPlaybackInteractive
			playback.switch_to_clip_by_name("Knockout")
	
func is_dead():
	return stamina <= 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dead():
		return
	self._last_delta = delta
	if not launched:
		self.global_position = launcher.crank_top_spot.global_position
		return
	time += delta
	reset_dash_timer -= delta
	if reset_dash_timer <= 0:
		reset_dash_timer = 5.0
		self.rocket_dash_available = true
	
	reduce_stamina(0.1*delta)
	if self.global_position.y < -10:
		self.spin_speed = 0.0
		if ai_controlled:
			self.ringout_sprite_animation.frame = 0
			self.ringout_sprite_animation.visible = true
			self.ringout_sprite_animation.play()
			var playback = self.announcer_audio_stream_player.get_stream_playback() as AudioStreamPlaybackInteractive
			playback.switch_to_clip_by_name("Ringout")
		return
	
	if self.get_colliding_bodies().size() > 0 and not is_dead():
		self.trail_particle_emitter.emitting = true
		self.sparks_particle_emitter.emitting = true
		
	else:
		self.trail_particle_emitter.emitting = false
		self.sparks_particle_emitter.emitting = false
		
		#personal_above_point = self.target_above_node.global_position
		
	#if self.linear_velocity.normalized().length_squared() > 0.01:
		#self.trail_particle_emitter.look_at(self.global_position - self.linear_velocity.normalized(), Vector3.UP)
		#self.trail_particle_emitter.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))
	
func spin_top():
	self.model.global_rotate(self.basis.y, wrapf(min(1.0, spin_speed), 0.0, (2*PI)))
	
	
func force_upright_top():
	var correction:Vector3 = self.global_basis.y.cross(Vector3.UP).normalized()
	if correction.length_squared() >= 0.01:
		self.apply_torque(correction * right_speed)
	
func force_lookat_top():
	if self.get_colliding_bodies().size() <= 0 or is_dead():
		return
	if self.global_position.y < self.personal_above_point.y:
		self.look_at_node.look_at_from_position(self.global_position, self.personal_above_point)
		self.look_at_node.rotate_object_local(Vector3(1, 0, 0), -PI / 2.0)
	
	var correction:Vector3 = self.global_basis.y.cross(look_at_node.basis.y).normalized()
	if correction.length_squared() >= 0.01:
		self.apply_torque(correction * right_speed *2.0)
	
func rocket_dash(distance_from_center:float):
	if not self.rocket_dash_available:
		return
	var move_direction:Vector3 = (self.center_point - self.global_position).normalized()
	if distance_from_center <= 6.0 and last_top_hit and not last_top_hit.is_dead():
		move_direction = (self.last_top_hit.global_position - self.global_position).normalized()
	move_direction.y = 0
	#move_direction.y = 0
	#self.apply_central_force(move_direction * center_speed)
	self.apply_central_impulse(move_direction * impulse_speed)
	self.rocket_dash_available = false
	
func impulse_to_target():
	if is_dead() or not self.rocket_dash_available:
		return
	
	var move_direction:Vector3 = (self.target_node.global_position - self.global_position).normalized()
	self.linear_velocity = Vector3.ZERO
	
	self.apply_central_impulse(move_direction * impulse_speed)
	
	
func move_in_current_direction():
	var move_direction:Vector3 = self.linear_velocity.normalized()
	if self.ai_controlled and last_top_hit and not last_top_hit.is_dead() and self.rocket_dash_available:
		move_direction = (self.last_top_hit.global_position - self.global_position).normalized()
	if not self.ai_controlled and not self.is_dead() and self.rocket_dash_available:
		move_direction = (self.target_node.global_position - self.global_position).normalized()
	
	if self.ai_controlled:
		return
	self.apply_central_force(move_direction * move_speed)
	

func _physics_process(_delta: float) -> void:
	if not launched:
		return
	if is_dead():
		return
	spin_top()
	#force_upright_top()
	force_lookat_top()
	move_in_current_direction()
	var distance_from_center:float = abs(self.global_position.distance_to(self.center_point))
	if ai_controlled:
		if distance_from_center >= 6.0 or randf_range(0, 1000) <= self.center_speed * distance_from_center:
			rocket_dash(distance_from_center)
	check_if_hidden()
	
func check_if_hidden():
	var cam := get_viewport().get_camera_3d()
	if cam == null or target_node == null:
		return
	var from: Vector3 = cam.global_position
	var to: Vector3 = self.global_position + Vector3(0, 0.5, 0)
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self.get_rid()]
	query.collision_mask = 2
	var hit := space_state.intersect_ray(query)
	
	if hit and hit.has("position"):
		self.outline_mesh.get_active_material(0).set_shader_parameter("outline_color", self.colour)
		for child in self.outline_mesh.get_children():
			child.get_active_material(0).set_shader_parameter("outline_color", self.colour)
		self.outline_mesh.visible = true
	else:
		self.outline_mesh.visible = false
	
