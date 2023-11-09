extends Action
class_name CombineCharacterConfigs
export (String) var encounter_name_override:String = ""
export (Array,String) var use_bb_keys = ["opponent","opponent2"]
export (Array,String) var ally_nodes
func _run():
	var encounter1 = get_encounter_node(self,encounter_name_override, 0)
	var npc_list:Array = []
	npc_list.push_back(encounter1.get_parent()) 
	var key_index:int = 1
	for key in use_bb_keys:
		if key == use_bb_keys[0]:
			continue		
		var encounter2 = get_encounter_node(self,encounter_name_override, key_index)		
		if encounter1 == null:
			push_error("Couldn't find EncounterConfig 1 for Combine Action")
			return false
		if encounter2 == null:
			push_error("Couldn't find EncounterConfig 2 for Combine Action")
			return false	
		
		var char2 = encounter2.get_character_nodes()
		npc_list.push_back(encounter2.get_parent())		
			
		encounter2.remove_child(char2[0])	
		encounter2.name = "DoNotUse"
		encounter1.add_child(char2[0])
		key_index += 1
	for node_name in ally_nodes:
		var char_node = get_current_scene().get_node(node_name)
		if char_node:
			var new_encounter = get_encounter_node(char_node,encounter_name_override)
			if new_encounter == null:
				push_error("Couldn't find EncounterConfig 2 for Combine Action")
				return false
			var char2 = new_encounter.get_character_nodes()
			npc_list.push_back(new_encounter.get_parent())
			encounter1.add_child(char2[0].duplicate())								
	var index = 0
	for character in encounter1.get_character_nodes():
		character.copy_human_sprite = npc_list[index].get_path()
		index += 1
	return true

func get_pawn():
	if values.size() > 0:
		return values[0]
	return .get_pawn()


func get_encounter_node(a:Node, name:String = "", index:int = -1)->EncounterConfig:
	if name == "":
		name = "EncounterConfig"
	if a.has_node(name):
		return a.get_node(name) as EncounterConfig	
	if a is Action:
		if a.values.size() > 0 and a.values[0] is EncounterConfig:
			return a.values[0]
		if index > -1:	
			return a.blackboard[use_bb_keys[index]].get_node(name)			
		if a.get_pawn().has_node(name):
			return a.get_pawn().get_node(name)
	return null

