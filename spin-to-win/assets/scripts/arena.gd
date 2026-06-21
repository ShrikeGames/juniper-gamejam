extends Node3D
class_name Arena

@export var spin:bool = false
@export var rotation_speed:float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if spin:
		self.global_rotate(Vector3.UP, rotation_speed * delta)
