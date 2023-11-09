extends Node

export (String) var object_to_inject
export (String) var scene_to_add_to

func _ready():	
	if SceneManager.current_scene.name == scene_to_add_to:
		var object = load(object_to_inject).instance()		
		get_parent().call_deferred("add_child", object)
