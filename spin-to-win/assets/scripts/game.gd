extends Node3D

var tops:Array[Top] = []
@export var camera:Camera3D
@export var scene_to_change_to:String
@export var gameover_scene_to_change_to:String
@export var arena_container:Node3D
@export var player_container:Node3D
@export var cpu_container:Node3D
@export var target_node:Node3D
@export var target_above_node:Node3D
@export var look_at_node:Node3D
@export var knockout_sprite_animation:AnimatedSprite2D
@export var ringout_sprite_animation:AnimatedSprite2D
@export var gameover_sprite_animation:AnimatedSprite2D
@export var youwin_sprite_animation:AnimatedSprite2D
@export var announcer_audio_stream_player:AudioStreamPlayer

var player_launcher:Launcher
var player_top:Top

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
	var num_cpus:int = Global.game_state["next_match"].get("num_cpus", 1)
	var arena_id:int = Global.game_state["next_match"].get("arena_id", 0)
	
	var arena = Global.arena_resources[arena_id].instantiate()
	arena_container.add_child(arena)
	
	player_launcher = launcher_resource.instantiate()
	player_container.add_child(player_launcher)
	var player_pos:Vector3 = Vector3(0,5,5)
	player_launcher.global_position = player_pos
	player_launcher.look_at(Vector3(0,5,0))
	
	player_top = top_resource.instantiate()
	player_top.target_node = target_node
	player_top.target_above_node = target_above_node
	player_top.look_at_node = look_at_node
	player_top.launcher = player_launcher
	player_top.launched = false
	player_top.center_speed = Global.game_state["stats"]["center_speed"]
	player_top.move_speed = Global.game_state["stats"]["move_speed"]
	player_top.spin_speed = Global.game_state["stats"]["spin_speed"]
	player_top.right_speed = Global.game_state["stats"]["right_speed"]
	player_top.impulse_speed = Global.game_state["stats"]["impulse_speed"]
	player_top.ai_controlled = false
	player_top.mass = max(0.1, Global.game_state["stats"]["mass"])
	player_top.knockout_sprite_animation = self.knockout_sprite_animation
	player_top.ringout_sprite_animation = self.ringout_sprite_animation
	player_top.announcer_audio_stream_player = self.announcer_audio_stream_player
	
	player_top.colour = Color(Global.game_state["stats"]["colour"]["r"], Global.game_state["stats"]["colour"]["g"], Global.game_state["stats"]["colour"]["b"])
	
	player_container.add_child(player_top)
	
	player_top.global_position = player_launcher.crank_top_spot.global_position
	var num_wins:int = min(20, Global.game_state["stats"]["wins"])
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
		cpu_top.center_speed = randf_range(8.0+num_wins, 12.0+num_wins)
		cpu_top.move_speed = randf_range(8.0+num_wins, 12.0+num_wins)
		cpu_top.spin_speed = randf_range(10.0+num_wins, 12.0+num_wins)
		cpu_top.right_speed = randf_range(12.0+num_wins, 15.0+num_wins)
		cpu_top.impulse_speed = randf_range(8.0+num_wins, 16.0+num_wins)
		cpu_top.ai_controlled = true
		cpu_top.mass = randf_range(0.75+(num_wins*0.1), 1.5+(num_wins*0.1))
		cpu_top.knockout_sprite_animation = self.knockout_sprite_animation
		cpu_top.ringout_sprite_animation = self.ringout_sprite_animation
		cpu_top.announcer_audio_stream_player = self.announcer_audio_stream_player
		
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
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if youwin_sprite_animation.visible or gameover_sprite_animation.visible:
		return
	
	if player_top and camera.is_launched:
		camera.look_at(player_top.global_position)
	if camera.rotate_crank or not player_top.launched:
		player_top.linear_velocity = Vector3.ZERO
		player_top.angular_velocity = Vector3.ZERO
	if camera.rotate_crank:
		var distance_bonus:float = min(5.0, max(0.0, camera.mouse_distance_traveled * 0.001))
		player_launcher.crank.rotate(Vector3.UP, -distance_bonus*0.1)
	
	var dead_tops:int = 0
	for top in tops:
		if top.spin_speed <= 0:
			dead_tops +=1
	if dead_tops >= len(tops) and player_top.spin_speed > 0 and not youwin_sprite_animation.visible:
		# win
		youwin_sprite_animation.frame = 0
		youwin_sprite_animation.visible = true
		youwin_sprite_animation.play()
		var playback = self.announcer_audio_stream_player.get_stream_playback() as AudioStreamPlaybackInteractive
		playback.switch_to_clip_by_name("You Win")
		
		
	if player_top.spin_speed <= 0 and not gameover_sprite_animation.visible:
		# gameover
		print("play game over animation and sound")
		Global.game_state["stats"] = Global.default_game_state["stats"].duplicate(true)
		Global.game_state["next_match"] = Global.default_game_state["next_match"].duplicate(true)
		Global.save_settings()
		gameover_sprite_animation.frame = 0
		gameover_sprite_animation.visible = true
		gameover_sprite_animation.play()
		var playback = self.announcer_audio_stream_player.get_stream_playback() as AudioStreamPlaybackInteractive
		playback.switch_to_clip_by_name("Gameover")


func _on_knockout_sprite_animation_animation_finished() -> void:
	self.knockout_sprite_animation.visible = false


func _on_ringout_sprite_animation_animation_finished() -> void:
	self.ringout_sprite_animation.visible = false


func _on_gameover_sprite_animation_animation_finished() -> void:
	get_tree().change_scene_to_file(gameover_scene_to_change_to)


func _on_youwin_sprite_animation_animation_finished() -> void:
	Global.game_state["stats"]["wins"] += 1
	Global.save_settings()
	get_tree().change_scene_to_file(scene_to_change_to)


func _on_countdown_sprite_animation_animation_finished() -> void:
	player_top.launched = true
	player_top.impulse_to_target()
	var distance_bonus:float = min(5.0, max(0.0, camera.mouse_distance_traveled * 0.001))
	player_top.move_speed += distance_bonus
	player_top.right_speed += distance_bonus
	player_top.spin_speed += distance_bonus
	player_launcher.visible = false
	camera.is_launched = true
	camera.mouse_distance_traveled = 0.0
	for cpu in cpu_container.get_children():
		if is_instance_of(cpu, Top):
			cpu.launched = true
		if is_instance_of(cpu, Launcher):
			cpu.visible = false
	camera.countdown_animation.visible = false
	camera.countdown_animation.stop()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if camera.is_launched and event.is_action_pressed("LMB"):
			var cam := get_viewport().get_camera_3d()
			if cam == null or target_node == null:
				return
			var mouse_pos: Vector2 = event.position
			var from: Vector3 = cam.project_ray_origin(mouse_pos)
			var dir: Vector3 = cam.project_ray_normal(mouse_pos)
			var to: Vector3 = from + dir * camera.max_ray_distance
			var space_state := get_world_3d().direct_space_state
			var query := PhysicsRayQueryParameters3D.create(from, to)
			query.collision_mask = camera.ground_mask
			var hit := space_state.intersect_ray(query)
			if hit and hit.has("position"):
				camera.target_node.global_position = hit["position"]
				self.player_top.impulse_to_target()
		else:
			# hold LMB and spin mouse to spin the crank
			if event.is_action_pressed("LMB") and event.pressed:
				camera.rotate_crank = true
			if event.is_action_released("LMB"):
				camera.rotate_crank = false
