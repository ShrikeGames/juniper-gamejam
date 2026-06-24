extends RigidBody3D
class_name Top

@export var disabled:bool = false
@export var top_name:String = "Top"
@export var model:MeshInstance3D
@export var trail_particle_emitter:GPUParticles3D
@export var sparks_particle_emitter:GPUParticles3D
@export var target_node:Node3D
@export var center_point:Vector3 = Vector3.ZERO
@export var target_above_node:Node3D
@export var look_at_node:Node3D
@export var arrow:Node3D
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
@export var core_mesh:MeshInstance3D
var announcer_audio_stream_player:AudioStreamPlayer

@export var collision_audio_player:AudioStreamPlayer3D
@export var other_audio_player:AudioStreamPlayer3D
@export var ai_controlled:bool = false
@export var stamina_progress_bar:TextureProgressBar
@export var tops:Array[Top] = []
@export var shockwave_model:MeshInstance3D

var ult:int = 0
var knockout_sprite_animation:AnimatedSprite2D
var ringout_sprite_animation:AnimatedSprite2D

var personal_above_point:Vector3
var last_top_hit:Top

var _last_delta:float
var reset_dash_timer:float
var current_stats:Dictionary

var stamina:float = 3.0
var max_stamina:float = 3.0
var on_ground:bool = false

var iframe_timer_sec:float = 0
var max_iframes_sec:float = 0.25
var ult_available:bool = false
var stored_colour:Color
var stored_mass:float


func _ready() -> void:
	if disabled:
		return
	self.arrow.visible = not ai_controlled
	personal_above_point = self.target_above_node.global_position
	reset_dash_timer = 0
	on_ground = false
	
	var collision_audio_player_stream = preload("res://assets/sound/top_collision_audio.tres")
	collision_audio_player.stream = collision_audio_player_stream
	collision_audio_player.play()
	var other_audio_player_stream = preload("res://assets/sound/top_other_audio.tres")
	other_audio_player.stream = other_audio_player_stream
	other_audio_player.play()
	
	update_appearance()

func update_appearance():
	var material = StandardMaterial3D.new()
	material.albedo_color = colour
	self.model.material_override = material
	for child in self.model.find_children("test_top", "MeshInstance3D"):
		child.material_override = material
	var core_material = StandardMaterial3D.new()
	core_material.albedo_color = Global.ult_colours[self.ult]
	self.core_mesh.material_override = core_material
	
func update_based_on_stats(stats:Dictionary):
	self.current_stats = stats
	var human_bonus:float = 1.5 - min(0.6, stats.get("wins", 0)* 0.05)
	if Global.game_state["settings"]["gameplay"]["easymode"]:
		human_bonus += 0.5
	if ai_controlled:
		human_bonus = 1.0
		if Global.game_state["settings"]["gameplay"]["easymode"]:
			human_bonus = 0.5
	# "Dexterity": 2, # +move speed, +spin speed, -weight, +green
	# "Power": 2, # +force, +weight, (+right speed), +red
	# "Special": 2, # +rocket dash, +force, +ult, +blue
	# "Ult": 0, # id for ultimate ability
	self.move_speed += stats["Dexterity"] * human_bonus
	self.spin_speed += stats["Dexterity"] * 2.0 * human_bonus
	self.mass -= stats["Dexterity"] * 0.01
	self.colour.g = (stats["Dexterity"]-1) * 0.2
	
	self.force_multiplier += stats["Power"]
	self.mass += stats["Power"] * 0.1
	self.move_speed += stats["Power"] * 0.5 * human_bonus
	self.right_speed += stats["Power"] * 3.0 * human_bonus
	self.colour.r = (stats["Power"]-1) * 0.2
	
	self.impulse_speed += stats["Special"] * human_bonus
	self.force_multiplier += stats["Special"] * 0.5
	# TODO, ult power
	self.colour.b = (stats["Special"]-1) * 0.2
	
	self.max_stamina = ((stats["Dexterity"]*2.0) + stats["Power"] + (stats["Special"]*0.5)) * 3.0  * human_bonus
	self.stamina = self.max_stamina
	self.stamina_progress_bar.max_value = self.max_stamina
	self.stamina_progress_bar.value = self.stamina
	
	self.ult = stats["Ult"]
	# print(stats, ": ", self.colour)
	update_appearance()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if disabled:
		return
	if not launched or is_dead():
		return
	var contact_count = state.get_contact_count()
	on_ground = false
	for i in contact_count:
		var contact_pos:Vector3 = state.get_contact_collider_position(i)
		var collider_object = state.get_contact_collider_object(i)
		
		self.sparks_particle_emitter.global_position = contact_pos
		self.sparks_particle_emitter.amount = max(1, int(spin_speed)*10.0)
		var collision_normal:Vector3 = state.get_contact_local_normal(i)
		personal_above_point = self.global_position + ((collision_normal.normalized()) + (self.linear_velocity.normalized()*0.5)).normalized() * 2.0
		# hitting the table outside of the arena insta-kills you
		if is_instance_of(collider_object, Table):
			self.stamina = 0
			if ai_controlled:
				self.ringout_sprite_animation.frame = 0
				self.ringout_sprite_animation.visible = true
				self.ringout_sprite_animation.play()
				var playback = self.announcer_audio_stream_player.get_stream_playback() as AudioStreamPlaybackInteractive
				playback.switch_to_clip_by_name("Ringout")
			return
		elif is_instance_of(collider_object, StaticBody3D):
			self.on_ground = true
			self.ult_available = true
			var random_clank_id:int = randi_range(1,2)
			var clip_name:String = "On Ground %d"%random_clank_id
			play_other_audio_clip(clip_name)
		
		if is_instance_of(collider_object, Top):
			var speed_force:Vector3 = self.linear_velocity.normalized()
			var angular_force:Vector3 = self.angular_velocity.normalized()
			
			var total_force:Vector3 = (speed_force + angular_force).normalized() * self.force_multiplier * 2.0
			#total_force.y = 0
			if abs(self.linear_velocity.length()) <= 5.0:
				var new_force:Vector3 = self.basis.z.normalized() * move_speed
				total_force += new_force
			
			var stamina_drain:float = max(1, (self.current_stats["Power"] * 1.2) - collider_object.current_stats["Power"])
			
			if not collider_object.is_dead() and collider_object.iframe_timer_sec < 0:
				collider_object.reduce_stamina(stamina_drain)
				collider_object.apply_central_impulse(total_force)
				var opposite_force:Vector3 = -total_force
				opposite_force.y = 0
				self.apply_central_impulse(opposite_force)
			
			var random_clank_id:int = randi_range(1,9)
			var clip_name:String = "Clang %d"%random_clank_id
			play_collision_audio_clip(clip_name)
			last_top_hit = collider_object
			collider_object.iframe_timer_sec = collider_object.max_iframes_sec
			
		elif contact_pos.y <= self.global_position.y - 0.1:
			if ai_controlled:
				last_top_hit = null
			
			var speed_force:Vector3 = self.linear_velocity.normalized()
			var angular_force:Vector3 = self.angular_velocity.normalized()
			
			var total_force:Vector3 = (speed_force + angular_force).normalized() * self.force_multiplier * 2.0
			#total_force.y = 0
			if abs(self.linear_velocity.length()) <= 5.0:
				var new_force:Vector3 = self.basis.z.normalized() * move_speed
				total_force += new_force
			
			var opposite_force:Vector3 = -total_force
			opposite_force.y = 0
			self.apply_central_impulse(opposite_force)
			
			var random_clank_id:int = randi_range(1,9)
			var clip_name:String = "Clang %d"%random_clank_id
			play_collision_audio_clip(clip_name)
			var stamina_drain:float = 0.1
			self.reduce_stamina(stamina_drain)
		else:
			var stamina_drain:float = 0.01
			self.reduce_stamina(stamina_drain)
			on_ground = true

func play_collision_audio_clip(clip_name:String):
	if disabled:
		return
	#print("Play clip %s"%[clip_name])
	var playback = self.collision_audio_player.get_stream_playback() as AudioStreamPlaybackInteractive
	self.collision_audio_player.pitch_scale = randf_range(0.5, 1.5)
	playback.switch_to_clip_by_name(clip_name)

func play_other_audio_clip(clip_name:String):
	if disabled:
		return
	#print("Play clip %s"%[clip_name])
	var playback = self.other_audio_player.get_stream_playback() as AudioStreamPlaybackInteractive
	self.other_audio_player.pitch_scale = randf_range(0.5, 1.5)
	playback.switch_to_clip_by_name(clip_name)

func reduce_stamina(drain_amount:float = 0.1):
	if disabled:
		return
	var total_drain_amount:float = drain_amount
	if self.mass > self.current_stats.get("mass", self.mass) * 1.25:
		total_drain_amount *= 0.5
	
	self.stamina = max(0.0, self.stamina-total_drain_amount)
	self.stamina_progress_bar.value = self.stamina
	if is_dead():
		move_speed = 0.0
		impulse_speed = 0.0
		right_speed = 0.0
		spin_speed = 0.0
		trail_particle_emitter.emitting = false
		sparks_particle_emitter.emitting = false
		if ai_controlled:
			self.knockout_sprite_animation.frame = 0
			self.knockout_sprite_animation.visible = true
			self.knockout_sprite_animation.play()
			var playback = self.announcer_audio_stream_player.get_stream_playback() as AudioStreamPlaybackInteractive
			playback.switch_to_clip_by_name("Knockout")
	
func is_dead():
	if disabled:
		return true
	return stamina <= 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if disabled:
		return
	if is_dead():
		return
		
	
	self._last_delta = delta
	if not launched:
		self.global_position = launcher.crank_top_spot.global_position
		return
	time += delta
	iframe_timer_sec -= delta
	
	reset_dash_timer -= delta
	if reset_dash_timer <= 0:
		last_top_hit = tops[0]
	
	reduce_stamina(0.1*delta)
	if self.stored_mass and self.mass > self.stored_mass:
		var decrease_amount:float = delta*0.5
		self.mass = clampf(self.mass - (decrease_amount), self.stored_mass, self.mass)
		if self.mass <= self.stored_mass:
			self.colour = self.stored_colour
			self.mass = self.stored_mass
			self.ult_available = true
			self.update_appearance()
		
	
	if self.global_position.y < -10:
		self.stamina = 0.0
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
		
	
func spin_top():
	if disabled:
		return
	self.model.global_rotate(self.basis.y, wrapf(min(1.0, spin_speed), 0.0, (2*PI)))
	
	
func force_upright_top():
	if disabled:
		return
	var correction:Vector3 = self.global_basis.y.cross(Vector3.UP).normalized()
	if correction.length_squared() >= 0.01:
		self.apply_torque(correction * right_speed)
	
func force_lookat_top(_delta: float):
	if disabled:
		return
	if self.get_colliding_bodies().size() <= 0 or is_dead():
		return
	#if self.global_position.y < self.personal_above_point.y:
		#var up_direction:Vector3 = Vector3.UP
		#self.look_at_node.look_at_from_position(self.global_position, self.personal_above_point, up_direction)
		#self.look_at_node.rotate_object_local(Vector3(1, 0, 0), -PI / 2.0)
	#
	if self.global_position.y + 0.5 < self.personal_above_point.y:
		self.look_at_node.look_at_from_position(self.global_position, self.personal_above_point)
		self.look_at_node.rotate_object_local(Vector3(1, 0, 0), -PI / 2.0)
		var correction:Vector3 = self.global_basis.y.cross(look_at_node.basis.y).normalized()
		if abs(correction.length()) >= 0.1:
			self.apply_torque_impulse(correction * right_speed)
	
func activate_ult():
	if disabled or not self.ult_available:
		return
	if ult == 0:
		if ai_controlled:
			rocket_dash()
		else:
			impulse_to_target()
	elif ult == 1:
		rocket_jump()
	elif ult == 2:
		shockwave()
	elif ult == 3:
		defend()
	elif ult == 4:
		katana()
	
	ult_available = false

func katana():
	pass

func defend():
	if self.mass > self.current_stats.get("mass", self.mass):
		return
	#print("defend")
	self.stored_mass = self.mass
	self.stored_colour = self.colour
	self.mass += 0.5 + (self.current_stats["Special"] * 1.2)
	self.colour.r = 0.0
	self.colour.b = 0.0
	self.colour.g = 0.0
	self.update_appearance()

func shockwave():
	var hit_top:bool = false
	var distance:float = self.current_stats["Special"] * 1.2
	if not shockwave_model.visible:
		shockwave_model.scale = Vector3.ZERO
		shockwave_model.max_size = distance
		shockwave_model.expansion_speed = self.force_multiplier*5.0
		shockwave_model.visible = true
		hit_top = true
	for top in tops:
		if top == self:
			continue
		var diff:Vector3 = top.global_position - self.global_position
		
		if abs(diff.length()) <= distance:
			diff.y = 0
			top.apply_central_impulse(diff.normalized()*self.force_multiplier*5.0)
			
	if hit_top:
		self.apply_central_impulse(Vector3.UP * self.force_multiplier * 2.0)
	

func rocket_jump():
	if disabled:
		return
	var move_direction:Vector3 = (self.center_point - self.global_position).normalized()
	move_direction.y = 1
	#print("rocket jump", move_direction * impulse_speed)
	self.linear_velocity = Vector3.ZERO
	self.apply_central_impulse(move_direction * impulse_speed * 0.75)


func rocket_dash():
	if disabled:
		return
	var move_direction:Vector3 = (self.center_point - self.global_position).normalized()
	if last_top_hit and not last_top_hit.is_dead():
		move_direction = (self.last_top_hit.global_position - self.global_position).normalized()
	
	#move_direction.y = 0
	#self.apply_central_force(move_direction * center_speed)
	self.apply_central_impulse(move_direction * impulse_speed * 1.25)
	
func impulse_to_target():
	if disabled:
		return
	if is_dead():
		return
	#print("impulse to target")
	var move_direction:Vector3 = (self.target_node.global_position - self.global_position).normalized()
	move_direction.y = 0
	self.linear_velocity = Vector3.ZERO
	
	self.apply_central_impulse(move_direction * impulse_speed * 1.25)
	
	
func move_in_current_direction(delta):
	if disabled:
		return
	
	var move_direction:Vector3 = self.linear_velocity.normalized()
	if ai_controlled and (self.global_position.length() > 6) and last_top_hit == null:
		move_direction = (self.center_point - self.global_position).normalized()
		if ult in [1,2]:
			activate_ult()
	elif ai_controlled and (self.global_position.length() > 12) and last_top_hit != null:
		move_direction = (self.center_point - self.global_position).normalized()
		if ult in [1,2]:
			activate_ult()
	else:
		if self.ai_controlled and last_top_hit and not last_top_hit.is_dead():
			move_direction = (self.last_top_hit.global_position - self.global_position).normalized()
		if not self.ai_controlled and not self.is_dead():
			move_direction = (self.target_node.global_position - self.global_position).normalized()
	if not ai_controlled:
		self.arrow.look_at(self.global_position + (move_direction * move_speed))
		
	self.apply_central_force(move_direction * move_speed * 60.0 * delta)
	

func _physics_process(delta: float) -> void:
	if disabled:
		return
	if not launched:
		return
	if is_dead():
		return
	spin_top()
	#force_upright_top()
	force_lookat_top(delta)
	move_in_current_direction(delta)
	if ai_controlled:
		if randf_range(0, 2000) <= self.center_speed * self.current_stats["Special"]:
			activate_ult()
	check_if_hidden()
	
func check_if_hidden():
	if disabled:
		return
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
	
