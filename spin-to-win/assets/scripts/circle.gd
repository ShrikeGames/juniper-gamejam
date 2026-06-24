extends Sprite2D

var time:float = randf()
var center_point:Vector2
var radius:float = 200.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_point = self.global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	self.global_position.x = center_point.x + sin(-time * 1.5) * radius
	self.global_position.y = center_point.y + cos(-time * 1.5) * radius
	
