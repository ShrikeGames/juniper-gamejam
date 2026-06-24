extends MeshInstance3D

@export var max_size:float = 3.0
@export var expansion_speed:float = 1.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if self.visible:
		self.scale.x += delta * expansion_speed
		self.scale.y += delta * expansion_speed
		self.scale.z += delta * expansion_speed
	
	if self.scale.z >= max_size:
		self.visible = false
		self.scale = Vector3.ZERO
	
