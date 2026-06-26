extends Node3D
var launcher_resource: Resource = load("res://assets/scenes/launcher.tscn")
var top_resource: Resource = load("res://assets/scenes/top.tscn")
@export var num_cpus:int = 3
@export var target_node: Node3D
@export var target_above_node: Node3D
@export var look_at_node: Node3D
@export var cpu_container:Node3D
@export var top_panels_container: GridContainer
var tops:Array[Top]
@export var knockout_sprite_animation: AnimatedSprite2D
@export var ringout_sprite_animation: AnimatedSprite2D
@export var gameover_sprite_animation: AnimatedSprite2D
@export var youwin_sprite_animation: AnimatedSprite2D
@export var announcer_audio_stream_player: AudioStreamPlayer
var random_positions: Array[Vector3] = get_circle_positions(6.0, 6.0)
var last_ult:int = 0
var pos_index:int = 0
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
	tops = []
	
	for i in range(num_cpus):
		var new_cpu_top: Top = top_resource.instantiate()
		new_cpu_top = spawn_random_cpu(new_cpu_top, true)
		
	
		var cpu_panel_card: TopPanelCard = Global.top_panel_card_resource.instantiate()
		cpu_panel_card.top = new_cpu_top
		top_panels_container.add_child(cpu_panel_card)
		tops.append(new_cpu_top)
	
	for top in tops:
		top.tops = tops

func spawn_random_cpu(cpu_top:Top, add_to_scene:bool = false):
	var random_index:int = wrapi(pos_index+1, 0, len(random_positions)-1)
	pos_index += randi_range(5, 10)
	var cpu_pos: Vector3 = random_positions[random_index]
	cpu_top.target_node = target_node
	cpu_top.target_above_node = target_above_node
	cpu_top.look_at_node = look_at_node
	cpu_top.top_name = Global.get_random_name()
	cpu_top.launcher = null
	cpu_top.last_top_hit = null
	cpu_top.center_point = Vector3.ZERO
	var cpu_stats: Dictionary = {
		"Dexterity": 1, # +move speed, +spin speed, -weight, +green
		"Power": 1, # +force, +weight, (+right speed), +red
		"Special": 1, # +rocket dash, +force, +ult, +blue
		"Ult": wrapf(last_ult+1, 0, len(Global.ult_names)-2), # id for ultimate ability
	}
	last_ult += 1
	for n in range(1):
		var possible_stats_to_increase: Array[String] = ["Dexterity", "Power", "Special"]
		var increase_stat: String = possible_stats_to_increase.pick_random()
		var index_to_remove: int = possible_stats_to_increase.find(increase_stat)
		possible_stats_to_increase.remove_at(index_to_remove)
		var decrease_stat: String = possible_stats_to_increase.pick_random()
		cpu_stats[increase_stat] = min(5, max(1, cpu_stats[increase_stat] + 2))
		cpu_stats[decrease_stat] = min(5, max(1, cpu_stats[decrease_stat] - 1))
	cpu_top.update_based_on_stats(cpu_stats)
	cpu_top.ai_controlled = true
	cpu_top.knockout_sprite_animation = self.knockout_sprite_animation
	cpu_top.ringout_sprite_animation = self.ringout_sprite_animation
	cpu_top.announcer_audio_stream_player = self.announcer_audio_stream_player
	if add_to_scene:
		cpu_container.add_child(cpu_top)
	cpu_top.global_position = cpu_pos
	cpu_top.launched = true
	cpu_top.linear_velocity = Vector3.ZERO
	cpu_top.angular_velocity = Vector3.ZERO
	return cpu_top

func _process(_delta: float) -> void:
	for top in tops:
		if top.is_dead():
			spawn_random_cpu(top)
		elif top.last_top_hit == null or top.last_top_hit == top:
			top.last_top_hit = tops.pick_random()
