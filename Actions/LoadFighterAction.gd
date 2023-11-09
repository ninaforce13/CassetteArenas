extends Action

export (int, "Scene", "Pawn", "Position Node") var parent:int = 0
export (String) var parent_offset:String
export (Vector3) var offset:Vector3
export (String) var set_bb_key:String = ""
export (String) var node_name:String = ""
export (String) var add_to_group:String = ""
export (bool) var copy_full_transform:bool = true
export (String) var load_bb_key:String = "custom_trainee_dictionary"
const emptytrainee = preload("res://mods/RangerArena/Fighters/EmptyTrainee.tscn")
func _run():
	var recruit = get_bb(load_bb_key)
	if not recruit:
		return false
	var new_trainee = emptytrainee.instance()
	new_trainee.sprite_part_names = JSON.parse(recruit.human_part_names).result
	new_trainee.sprite_colors = JSON.parse(recruit.human_colors).result
	new_trainee.pronouns = recruit.pronouns
	var entrydialog = new_trainee.get_node("EntryDialogue")
	entrydialog.title = recruit.name	
	var position = get_position()

	var node = new_trainee
	if node_name != "":
		node.name = node_name
	assert (node is Spatial)
	var parent_node
	if parent == 2 and position is Spatial:
		parent_node = position
	elif parent == 1:
		parent_node = get_pawn()
	else :
		parent_node = SceneManager.current_scene
	if parent_offset != "":
		parent_node = parent_node.get_node(parent_offset)
	parent_node.add_child(node, node_name != "")
	
	if position is Spatial:
		if copy_full_transform:
			node.global_transform = position.global_transform
			node.global_transform.origin += offset
		else :
			node.global_transform.origin = position.global_transform.origin + offset
	else :
		assert (position is Vector3)
		node.global_transform.origin = position + offset
	
	if set_bb_key != "":
		set_bb(set_bb_key, node)
	if add_to_group != "":
		node.add_to_group(add_to_group)

	return true


func get_position():
	if values.size() > 0:
		return values[0]
	var pawn = get_pawn()
	if pawn is Spatial:
		return pawn
	return Vector3()
