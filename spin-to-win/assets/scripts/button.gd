extends Button

@export var scene_to_change_to:String
@export var object_to_show:Container
@export var objects_to_hide:Array[Container]

func _on_pressed() -> void:
	Global.save_settings()
	
	if scene_to_change_to:
		get_tree().change_scene_to_file(scene_to_change_to)
	elif object_to_show:
		object_to_show.visible = true
		if objects_to_hide:
			for object_to_hide in objects_to_hide:
				object_to_hide.visible = false
				
