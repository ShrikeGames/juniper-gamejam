extends AnimatedSprite2D

var time:float = randf()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.rotation = randf_range(deg_to_rad(-45), deg_to_rad(45))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	self.scale = Vector2(1+sin(time*5.0)*0.5, 1+sin(time*5.0)*0.5)
	self.rotate(sin(time)*0.01)
	
