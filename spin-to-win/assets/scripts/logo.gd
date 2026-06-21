extends Sprite2D
var time:float = randf()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.rotation = randf_range(deg_to_rad(-5), deg_to_rad(5))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	self.scale = Vector2(1+sin(time)*0.05, 1+sin(time)*0.05)
	self.rotate(sin(time*0.5)*0.001)
	
