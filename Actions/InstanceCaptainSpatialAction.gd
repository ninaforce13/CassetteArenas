extends Action
class_name InstanceCaptainSpatialAction

enum captains {ZEDD = 0,
			   WALLACE = 1,
			   BUFFY = 2,
			   CLEEO = 3,
			   CODEY = 4,
			   CYBIL = 5,
			   PENNY = 6,
			   LODESTEIN = 7,
			   JUDAS = 8,
			   HEATHER = 9,
			   SKIP = 10,
			   GLADIOLA = 11,
			   IANTHE = 12,
			   WILMA = 13,
			}

export (captains) var captain_name
export (NodePath) var fighter_pool
export (Array, String) var partner_nodes = ["Partner2"]
export (int, "Scene", "Pawn", "Position Node") var parent:int = 0
export (String) var parent_offset:String
export (Vector3) var offset:Vector3
export (String) var set_bb_key:String = ""
export (String) var node_name:String = ""
export (String) var add_to_group:String = ""
export (bool) var copy_full_transform:bool = true

func _run():
		
	var position = get_position()
	var challenger = get_node(fighter_pool).get_captain(captain_name)
	var node = challenger.instance()
	if node_name != "":
		node.name = node_name
		
	configure_encounter(node)
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

func configure_encounter(node):
	var encounter_config = node.get_node("EncounterConfig")
	if not encounter_config:
		return	
	var npc_list:Array = []
	for partner_name in partner_nodes:
		if not SceneManager.current_scene.has_node(partner_name):
			return 
		var partner_node = SceneManager.current_scene.get_node(partner_name)
		if partner_node:
			var challenger = get_node(fighter_pool).get_random_fighter()
			var instanced_fighter = challenger.instance()
			instanced_fighter.visible = false
			SceneManager.current_scene.add_child(instanced_fighter)
			var new_config = instanced_fighter.get_node("EncounterConfig")
			var new_char = new_config.get_character_nodes()
			npc_list.push_back(new_config.get_parent())	
			new_config.remove_child(new_char[0])					
			encounter_config.add_child(new_char[0])			
			var partner_encounter = partner_node.get_node("EncounterConfig")
			if partner_encounter:
				var characters = partner_encounter.get_character_nodes()
				npc_list.push_back(partner_encounter.get_parent())
				encounter_config.add_child(characters[0].duplicate())
	var origin_index = 0
	var index = 0
	for character in encounter_config.get_character_nodes():
		if origin_index < 2:
			origin_index += 1
			continue
		character.copy_human_sprite = npc_list[index].get_path()
		index += 1
	return 

func get_position():
	if values.size() > 0:
		return values[0]
	var pawn = get_pawn()
	if pawn is Spatial:
		return pawn
	return Vector3()
