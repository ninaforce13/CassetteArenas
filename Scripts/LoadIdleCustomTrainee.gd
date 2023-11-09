extends Node

export (NodePath) var trainee_npc_path
export (NodePath) var trainee_manager_path

func _ready():
	if trainee_manager_path:
		var trainee_manager = get_node(trainee_manager_path) 
		var trainee_data = trainee_manager.get_a_trainee()
		if trainee_npc_path and trainee_data:
			var trainee_npc = get_node(trainee_npc_path)
			trainee_npc.npc_name = trainee_data.name
			trainee_npc.set_sprite_colors(JSON.parse(trainee_data.human_colors).result)
			trainee_npc.set_sprite_part_names(JSON.parse(trainee_data.human_part_names).result)
		if not trainee_data:
			var parent = get_parent()
			var child = get_node(trainee_npc_path)
#			parent.remove_child(child)
			parent.call_deferred("remove_child", child)
			child.queue_free()			
