extends Node

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
export (float) var named_fighter_chance = 0.2
export (float) var custom_trainee_chance = 0.6
export (Array, PackedScene) var global_fighter_pool
export (Array, PackedScene) var named_fighter_pool
export (Array, PackedScene) var captain_pool
export (Array, PackedScene) var captain_scenes
export (PackedScene) var wilma
export (bool) var demo_mode = false
export (bool) var custom_mode = false
export (PackedScene) var demo_fighter1
export (captains) var demo_captain
export (int) var fight_count:int = 3
export (int) var boss_intervals:int = 6
export (NodePath) var CutsceneNode
export (NodePath) var NodePlacement
export (NodePath) var partner2Initial

var global_forms
var current_cup
var challenger_custscene = preload("res://mods/RangerArena/Scenes/Challenger.tscn")
var emptytrainee = preload("res://mods/RangerArena/Fighters/EmptyTrainee.tscn")
var custom_trainee_pool:Array = []
var rangerdata = load("res://mods/RangerArena/JSON/RangerDataParser.gd")
func _init():		
	initialize_forms()
	initsavedata()	

	current_cup = SaveState.other_data.RangerArenaProperties["CurrentCup"]
	
func _ready():
	custom_mode = is_custom_cup()
	set_extra_partner()
	prepare_fighter_nodes()		
	add_custom_trainees()
	remove_partner()
	remove_extra_partner()

func set_extra_partner():
	if not SaveState.other_data.RangerArenaProperties.has(current_cup+"Partner1"):
		SaveState.set_flag("extra_partner1", false)
		return
	if SaveState.other_data.RangerArenaProperties[current_cup+"Partner1"] != null:
		var partner_data = SaveState.other_data.RangerArenaProperties[current_cup+"Partner1"]
		var partner = emptytrainee.instance()
		var parent = SceneManager.current_scene		
		partner.name = "Partner2"
		partner.npc_name = partner_data.name
		partner.global_transform = get_node(partner2Initial).global_transform
		partner.initial_direction = "up"
		rangerdata.set_npc_appearance(partner, partner_data)
		var char_config = partner.get_node("EncounterConfig/CharacterConfig")
		var tape1 = partner.get_node("EncounterConfig/CharacterConfig/SignatureTape")	
		var tape2 = partner.get_node("EncounterConfig/CharacterConfig/RandomTapeConfig")	
		var tape3 = partner.get_node("EncounterConfig/CharacterConfig/RandomTapeConfig2")	
		rangerdata.set_char_config(char_config,partner_data,tape1,tape2,tape3, true)
		char_config.team = 0
		parent.call_deferred("add_child", partner, true) 
		
		SaveState.set_flag("extra_partner1", true)
	else:
		SaveState.set_flag("extra_partner1", false)
		
func add_custom_trainees():
	var datapath = rangerdata.get_directory()
	var files:Array = rangerdata.get_files(datapath)
	var recruits:Array = rangerdata.read_json(files)
	var partner_data
	if SaveState.other_data.RangerArenaProperties.has(current_cup+"Partner1"): 
		partner_data = SaveState.other_data.RangerArenaProperties[current_cup+"Partner1"]
			
	for recruit in recruits:		
		var new_trainee = emptytrainee.instance()
		var tape1 = new_trainee.get_node("EncounterConfig/CharacterConfig/SignatureTape")
		var tape2 = new_trainee.get_node("EncounterConfig/CharacterConfig/RandomTapeConfig")
		var tape3 = new_trainee.get_node("EncounterConfig/CharacterConfig/RandomTapeConfig2")		
		var entry_dialog:Node = new_trainee.get_node("EntryDialogue")
		var defeat_dialog:Node = new_trainee.get_node("ExitDialogue")
		var char_config:Node = new_trainee.get_node("EncounterConfig/CharacterConfig")
		if partner_data != null:
			if Loc.tr(recruit.name) == Loc.tr(partner_data.name): 	
				continue
		new_trainee.sprite_part_names = JSON.parse(recruit.human_part_names).result
		new_trainee.sprite_colors = JSON.parse(recruit.human_colors).result
		new_trainee.pronouns = recruit.pronouns
		new_trainee.npc_name = recruit.name
		entry_dialog.title = recruit.name
		entry_dialog.messages.push_back(recruit.introdialog)
		
		defeat_dialog.title = recruit.name
		defeat_dialog.messages.push_back(recruit.defeatdialog)
		
		char_config.character_name = recruit.name
		char_config.pronouns = new_trainee.pronouns
		var char_stats:Character = Character.new()		
		if recruit.has("stats"):
			if recruit["stats"].size() > 0:
				char_stats.set_snapshot(recruit["stats"],1)
			
		char_config.base_character = char_stats
		if not recruit.has("stats"):
			char_config.base_character.base_max_hp = 120
		var index:int = 0
		for key in recruit:
			if str(key) == "tape"+str(index):
				if recruit[key].favorite:
					tape1.tape_snapshot = recruit[key]
					var snapshot = rangerdata.get_custom_monster(recruit[key])
					var form = load(snapshot.form)
					if form:
						char_config.base_character.partner_signature_species = form
				else:
					tape2.monster_profile.push_back(recruit[key])
					tape3.monster_profile.push_back(recruit[key])
				index += 1 
		var packed_scene = PackedScene.new()
		packed_scene.pack(new_trainee)
		custom_trainee_pool.push_back(packed_scene)
	refresh_custom_pool()
	
func remove_partner():
	var index = 0
	for fighter in named_fighter_pool:
		var instance = fighter.instance()	
		if Loc.tr(instance.npc_name) == Loc.tr(SaveState.party.partner.name): 
			exclude_named_encounter(index)
			instance.queue_free()
			break	
		instance.queue_free()
		index += 1
		
func remove_extra_partner():
	if not SaveState.other_data.RangerArenaProperties.has(current_cup+"Partner1"):
		return	
	if SaveState.other_data.RangerArenaProperties[current_cup+"Partner1"] != null:
		var partner_data = SaveState.other_data.RangerArenaProperties[current_cup+"Partner1"]
		var index = 0
		for fighter in custom_trainee_pool:
			var instance = fighter.instance()	
			if Loc.tr(instance.npc_name) == Loc.tr(partner_data.name): 			
				exclude_custom_encounter(index)
				instance.queue_free()
				break	
			instance.queue_free()
			index += 1	
		index = 0	
		for fighter in named_fighter_pool:
			var instance = fighter.instance()	
			if Loc.tr(instance.npc_name) == Loc.tr(partner_data.name): 
				exclude_named_encounter(index)
				instance.queue_free()
				break	
			instance.queue_free()
			index += 1					
				
func prepare_fighter_nodes():
	
	if (int(get_win_streak() + fight_count) % int(boss_intervals) == 0) and not custom_mode:
		var captain_node
		if demo_mode:
			captain_node = get_random_captain_node(demo_captain)	
		else:
			captain_node = get_random_captain_node()
		get_node(CutsceneNode).add_child_below_node(get_node(NodePlacement), captain_node.instance())		

	for _i in fight_count:
		var fighter_action = challenger_custscene		
		get_node(CutsceneNode).add_child_below_node(get_node(NodePlacement), fighter_action.instance())


func get_random_captain_node(_demo_index = -1)->PackedScene:
	if demo_mode and _demo_index > -1:
		return captain_scenes[_demo_index]
	if empty_captain_pool():
		refresh_captains()
	var captain_found:bool = false
	var captain_index = 0	
	var usable_indexes = []
	for i in captain_scenes.size():
		usable_indexes.push_back(i)
	while not captain_found:
		captain_index = usable_indexes[randi() % usable_indexes.size()]
		if captain_available(captain_index):
			captain_found = true
		usable_indexes.erase(captain_index)
		if usable_indexes.size() == 0:
			refresh_captains()
			for i in captain_scenes.size():
				usable_indexes.push_back(i)				
	var selection = captain_scenes[captain_index]	
	exclude_captain(captain_index)
	return selection

func refresh_captains():
	SaveState.other_data.RangerArenaProperties["BossEncounters"] = []

func empty_captain_pool()->bool:
	return SaveState.other_data.RangerArenaProperties["BossEncounters"].size() >= captain_scenes.size()

func exclude_captain(index:int):
	SaveState.other_data.RangerArenaProperties["BossEncounters"].push_back(index)	

func empty_named_pool()->bool:
	return SaveState.other_data.RangerArenaProperties["NamedEncounters"].size() >= named_fighter_pool.size()

func exclude_named_encounter(index:int):
	SaveState.other_data.RangerArenaProperties["NamedEncounters"].push_back(index)

func captain_available(index:int)->bool:
	return not SaveState.other_data.RangerArenaProperties["BossEncounters"].has(index)

func named_fighter_available(index:int):
	return not SaveState.other_data.RangerArenaProperties["NamedEncounters"].has(index)	

func random_fighter_available(index:int):
	return not SaveState.other_data.RangerArenaProperties["RandomEncounters"].has(index)

func custom_trainee_available(index:int):
	return not SaveState.other_data.RangerArenaProperties["CustomEncounters"].has(index)
	
func initsavedata():
	if not SaveState.other_data.has("RangerArenaProperties"):
		SaveState.other_data.RangerArenaProperties = {
													  "SavedTeam":[],
													  "CurrentCup":"",
													  "DebutTeam":[],
													  "RemastersTeam":[],
													  "MixTapesTeam":[],
													  "BootlegTeam":[],
													  "DebutStreak":0,
													  "RemastersStreak":0,
													  "MixTapesStreak":0,
													  "BootlegStreak":0,
													  "BossEncounters":[],
													  "NamedEncounters":[],
													  "RandomEncounters":[],
													  "CustomEncounters":[],
													  "LastRandomFighterIndex":-1,
													  "LastNamedFighterIndex":-1,
													  "LastCustomFighterIndex":-1,
													  "Overspill":false,
													}
	if not SaveState.other_data.RangerArenaProperties.has("CustomEncounters"):
		SaveState.other_data.RangerArenaProperties["CustomEncounters"] = []
	if not SaveState.other_data.RangerArenaProperties.has("LastCustomFighterIndex"):
		SaveState.other_data.RangerArenaProperties["LastCustomFighterIndex"] = -1		
		SaveState.other_data.RangerArenaProperties["Overspill"] = false		
	if not SaveState.other_data.RangerArenaProperties.has("FusionSet"):
		SaveState.other_data.RangerArenaProperties["FusionSet"] = true
	return true
		
func initialize_forms():
	global_forms = Datatables.load("res://data/monster_forms/").table.values()	

func get_full_remasters(forms)->Array:
	var result = []
	var evolutions = []
	for form in forms:
		if form.evolutions.size() == 0:
			evolutions.push_back(form)
	for evolution in evolutions:
		for form in forms:			
			for evolved_form in form.evolutions:
				if evolved_form.evolved_form == evolution:
					result.push_back(evolution) 	
	return result
	
func get_starters(forms)->Array:	
	var result = []
	var evolutions = []
	for form in forms:
		if form.evolutions.size() > 0:
			result.push_back(form)
			for evo in form.evolutions:
				evolutions.push_back(evo)
	for evo in evolutions:
		result.erase(evo.evolved_form)
	return result

func exclude_random_encounter(index):
	if SaveState.other_data.RangerArenaProperties["RandomEncounters"].has(index):
		return
	SaveState.other_data.RangerArenaProperties["RandomEncounters"].push_back(index)	

func exclude_custom_encounter(index):
#	if custom_trainee_pool.size() == 1:
#		return
	if SaveState.other_data.RangerArenaProperties["CustomEncounters"].has(index):
		return
	SaveState.other_data.RangerArenaProperties["CustomEncounters"].push_back(index)
	
func refresh():
	SaveState.other_data.RangerArenaProperties["RandomEncounters"] = []
	var last_index:int = SaveState.other_data.RangerArenaProperties["LastRandomFighterIndex"]
	if last_index > -1:
		exclude_random_encounter(last_index)

func refresh_custom_pool():
	SaveState.other_data.RangerArenaProperties["CustomEncounters"] = []
	remove_extra_partner()
	var last_index:int = SaveState.other_data.RangerArenaProperties["LastCustomFighterIndex"]
	if last_index > -1:
		exclude_custom_encounter(last_index)	
	
func refresh_named_fighters():	
	SaveState.other_data.RangerArenaProperties["NamedEncounters"] = []
	remove_partner()
	remove_extra_partner()
	var last_index:int = SaveState.other_data.RangerArenaProperties["LastNamedFighterIndex"]
	if last_index > -1:
		exclude_named_encounter(last_index)

func get_random_fighter()->PackedScene:
	if custom_mode:
		return get_custom_fighter()
	if named_fighter_trigger():
		return get_named_fighter()
	if custom_trainee_trigger():
		return get_custom_fighter()
	return get_trainee_fighter()

func get_custom_fighter()->PackedScene:
	if empty_custom_pool():
		refresh_custom_pool()
					
	var fighter_found:bool = false
	var fighter_index = 0	
	var usable_indexes = []
	for i in custom_trainee_pool.size():
		usable_indexes.push_back(i)
	while not fighter_found:
		fighter_index = usable_indexes[randi() % usable_indexes.size()]
		if custom_trainee_available(fighter_index):
			fighter_found = true
		usable_indexes.erase(fighter_index)
		if usable_indexes.size() == 0:
			refresh()
			for i in custom_trainee_pool.size():
				usable_indexes.push_back(i)				
	var selection = custom_trainee_pool[fighter_index]	
	SaveState.other_data.RangerArenaProperties["LastCustomFighterIndex"] = fighter_index
	exclude_custom_encounter(fighter_index)
	return selection
	
func get_trainee_fighter()->PackedScene:
		
	if empty_fighter_pool():
		refresh()
	if demo_mode:
		return demo_fighter1				
		
	var fighter_found:bool = false
	var fighter_index = 0	
	var usable_indexes = []
	for i in global_fighter_pool.size():
		usable_indexes.push_back(i)
	while not fighter_found:
		fighter_index = usable_indexes[randi() % usable_indexes.size()]
		if random_fighter_available(fighter_index):
			fighter_found = true
		usable_indexes.erase(fighter_index)
		if usable_indexes.size() == 0:
			refresh()
			for i in global_fighter_pool.size():
				usable_indexes.push_back(i)				
	var selection = global_fighter_pool[fighter_index]	
	SaveState.other_data.RangerArenaProperties["LastRandomFighterIndex"] = fighter_index
	exclude_random_encounter(fighter_index)
	return selection	

func get_named_fighter()->PackedScene:
	if empty_named_pool():
		refresh_named_fighters()
	var fighter_found:bool = false
	var fighter_index = 0	
	var usable_indexes = []
	for i in named_fighter_pool.size():
		usable_indexes.push_back(i)
	while not fighter_found:
		fighter_index = usable_indexes[randi() % usable_indexes.size()]
		if named_fighter_available(fighter_index):
			fighter_found = true
		usable_indexes.erase(fighter_index)
		if usable_indexes.size() == 0:
			refresh_named_fighters()
			for i in named_fighter_pool.size():
				usable_indexes.push_back(i)			
		
	var selection = named_fighter_pool[fighter_index]	
	SaveState.other_data.RangerArenaProperties["LastNamedFighterIndex"] = fighter_index
	exclude_named_encounter(fighter_index)
	return selection	

func named_fighter_trigger()->bool:
	return randf() < named_fighter_chance

func custom_trainee_trigger()->bool:
	return (randf() < custom_trainee_chance) and custom_trainee_pool.size() > 0 and custom_trainee_single_fix()

func custom_trainee_single_fix()->bool:
	if SaveState.other_data.RangerArenaProperties["LastCustomFighterIndex"] > -1 and custom_trainee_pool.size() == 1:
		SaveState.other_data.RangerArenaProperties["LastCustomFighterIndex"] = -1
		refresh_custom_pool()
		return false
	return true
		
	
func get_captain(index:int)->PackedScene:
	if index > 12:
		return wilma
	return captain_pool[index]

func empty_fighter_pool()->bool:
	return SaveState.other_data.RangerArenaProperties["RandomEncounters"].size() >= global_fighter_pool.size()

func empty_custom_pool()->bool:
	return SaveState.other_data.RangerArenaProperties["CustomEncounters"].size() >= custom_trainee_pool.size()
	
func get_win_streak()->int:
	if is_debut_cup():
		return SaveState.other_data.RangerArenaProperties["DebutStreak"]
	if is_remasters_cup():
		return SaveState.other_data.RangerArenaProperties["RemastersStreak"]
	if is_bootleg_cup():
		return SaveState.other_data.RangerArenaProperties["BootlegStreak"]	
	if is_mixtapes_cup():
		return SaveState.other_data.RangerArenaProperties["MixTapesStreak"]
	return 0
func is_debut_cup()->bool:
	return current_cup == "Debut"

func is_custom_cup()->bool:
	return current_cup == "Custom"

func is_remasters_cup()->bool:
	return current_cup == "Remasters"	

func is_bootleg_cup()->bool:
	return current_cup == "Bootleg"

func is_mixtapes_cup()->bool:
	return current_cup == "Mix Tapes"

func revert_remaster(tape)->MonsterForm:
	var basicform = tape.form

	if tape.form == null:
		var forms = get_starters(global_forms)
		basicform = forms[randi() % forms.size()]		
		return basicform
	if tape.form.evolutions.size() == 0:
		for form in global_forms:
			if form.evolutions.size() > 0:
				for evo in form.evolutions:
					if evo.evolved_form == basicform:				
						basicform = form
						break
		for form in global_forms:
			if form.evolutions.size() > 0:
				for evo in form.evolutions:
					if evo.evolved_form == basicform:
						basicform = form
						break
		
		if basicform == tape.form:
			var forms = get_starters(global_forms)
			basicform = forms[randi() % forms.size()]
	return basicform	

func remaster_form(tape)->MonsterForm:
	var forms = get_full_remasters(global_forms)
	if tape.form == null:
		return forms[randi() % forms.size()]			 
	var remastered_form
	
	for form in global_forms:			
		for evolved_form in form.evolutions:
			if evolved_form.evolved_form == tape.form:
				remastered_form = tape.form
				break 		
	if remastered_form == null:
		return forms[randi() % forms.size()]
		
	return remastered_form	
