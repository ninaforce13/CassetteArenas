extends "res://menus/BaseMenu.gd"

onready var world_human_sprite = find_node("WorldHumanSprite")
onready var battle_human_sprite = find_node("BattleHumanSprite")
onready var player_name_edit = find_node("PlayerName")
onready var content_container = find_node("ContentContainer")
onready var introtext = find_node("IntroDialogText")
onready var defeattext = find_node("DefeatDialogText")
onready var biotext = find_node("BioText")
onready var assigned_tapes = find_node("Tapes")
onready var stat_hex = find_node("StatHex")
onready var action_icon_buttons = [
	find_node("ChangeAppearanceButton"), 
	find_node("AssignTapesButton"),    
	find_node("ExitButton"), 
	find_node("SaveButton")
]
const DIRECTIONS = ["down", "right", "up", "left"]
const TapeAssignment = preload("TapeAssignmentMenu.tscn")
const StatMenu = preload("TraineeStatMenu.tscn")
const NPCCreator = preload("NPC_CreationMenu.tscn")
const trainee_base_stats = preload("res://mods/RangerArena/Characters/trainee.tres")
var rangerdata = preload("res://mods/RangerArena/JSON/RangerDataParser.gd")
var ranger_data:Dictionary = {"appearance":{}, "tapes":{}, "stats":{}, "filepath":""}
var tabs:Array
var current_index:int = 0
var time:float = 0.0
var loaded_recruit:Dictionary

func _ready():
	if loaded_recruit:
		load_recruit(loaded_recruit)	
		load_fighter(ranger_data["appearance"])
		load_tapes(ranger_data["tapes"])	
		load_stats(ranger_data["stats"])
	else:
		load_stats({})

func load_recruit(recruit:Dictionary):
	var appearance_fields = ["name","human_part_names","human_colors","pronouns","introdialog","defeatdialog","biotext","recruiter","recruiter_id"]
	var index:int = 0
	for key in recruit.keys():
		if key in appearance_fields:
			ranger_data["appearance"][key] = recruit[key]
		if key == "tape"+str(index):
			ranger_data["tapes"][key] = recruit[key]
			index += 1
		if key == "stats":
			ranger_data["stats"] = recruit[key]			
	ranger_data["filepath"] = recruit["filepath"]
func _on_SaveButton_pressed():	
	var focus_owner = get_focus_owner()
	if not appearance_data_is_valid():
		yield (GlobalMessageDialog.show_message("ARENAS_MISSING_TRAINEE_DATA"),"completed")
		return
	if not tapes_are_valid():
		yield (GlobalMessageDialog.show_message("ARENAS_MISSING_TAPE_DATA"), "completed")
		return
	if not stats_are_valid():
		yield (GlobalMessageDialog.show_message("ARENAS_MISSING_TRAINEE_STATS"), "completed")
		return	
	
	if yield(MenuHelper.confirm("ARENAS_INFO_CONFIRMATION"), "completed"):
		
		var merged_dictionary = merge(ranger_data["appearance"], ranger_data["tapes"],ranger_data["stats"])		
		var save_success
		if loaded_recruit:
			save_success = rangerdata.append_json(merged_dictionary, ranger_data["filepath"])
			merged_dictionary["filepath"] = ranger_data["filepath"]			
		if not loaded_recruit:	
			save_success = rangerdata.save_json(merged_dictionary)
		for button in action_icon_buttons:
			button.update_icon()
		
		GlobalMessageDialog.clear_state()
		if save_success:
			yield (GlobalMessageDialog.show_message(merged_dictionary.name + " has been successfully registered!"), "completed")
			choose_option(merged_dictionary)
		if not save_success:
			yield (GlobalMessageDialog.show_message("Error Saving File!"), "completed")

func stats_are_valid()->bool:
	return ranger_data["stats"].size() > 0	
func appearance_data_is_valid()->bool:
	return ranger_data["appearance"].has("name")
	
func tapes_are_valid()->bool:
	var tape_count:int = 0
	var has_favorite:bool = false
	for tape_key in ranger_data["tapes"].keys():
		tape_count += 1
		if ranger_data["tapes"][tape_key].favorite:
			has_favorite = true
		
	return tape_count > 2 and has_favorite

func merge(dict_1:Dictionary, dict_2:Dictionary,dict_3:Dictionary)->Dictionary:
	var new_dictionary: Dictionary = dict_1.duplicate(true)
	for key in dict_2:
		new_dictionary[key] = dict_2[key]	
	new_dictionary["stats"] = dict_3
	
	return new_dictionary	

func _on_ExitButton_pressed():
	if yield(MenuHelper.confirm("ARENAS_CANCEL_TRAINEE_CREATE"),"completed"):			
		choose_option(null)
		cancel()


func _on_ChangeAppearanceButton_pressed():
	var result = yield(show_appearance_menu(ranger_data["appearance"]), "completed")
	if result:
		load_fighter(result)
		ranger_data["appearance"] = result

func _process(delta):
	time += delta
	var rotations = int(time / 2.0) % 4
	world_human_sprite.direction = DIRECTIONS[rotations]

func load_fighter(result):
	player_name_edit.text = result.name
	world_human_sprite.colors = JSON.parse(result.human_colors).result
	world_human_sprite.part_names = JSON.parse(result.human_part_names).result
	battle_human_sprite.part_names = JSON.parse(result.human_part_names).result
	battle_human_sprite.colors = JSON.parse(result.human_colors).result
	introtext.text = result.introdialog
	defeattext.text = result.defeatdialog
	biotext.text = result.biotext
	battle_human_sprite.refresh()
	world_human_sprite.refresh()	
	
func load_tapes(result:Dictionary):
	var index:int = 0
	for child in assigned_tapes.get_children():
		var key = "tape"+str(index)
		var tape = MonsterTape.new()
		if result.has(key):
			result[key] = rangerdata.get_custom_monster(result[key])
			tape.set_snapshot(result[key], 1)
			child.get_child(0).tape = tape
		if not result.has(key):
			child.get_child(0).tape = null
		index +=1

func show_appearance_menu(current_appearance):
	var menu = NPCCreator.instance()
	menu.apperance_load = current_appearance
	menu.edit_mode = true if loaded_recruit else false
	MenuHelper.add_child(menu)
	var result = yield (menu.run_menu(), "completed")
	menu.queue_free()
	return result	
	
func show_tape_assignment_menu(current_tapes):
	var menu = TapeAssignment.instance()	
	menu.load_tapes = current_tapes
	MenuHelper.add_child(menu)
	var result = yield (menu.run_menu(), "completed")
	menu.queue_free()
	return result		

func show_stat_adjust_menu(character:Character):	
	var menu = StatMenu.instance()	
	menu.character = character
	MenuHelper.add_child(menu)
	var result = yield (menu.run_menu(), "completed")
	menu.queue_free()
	return result	
	
func _on_AssignTapesButton_pressed():
	var result = yield(show_tape_assignment_menu(ranger_data["tapes"]), "completed")
	if result:
		load_tapes(result)
		ranger_data["tapes"] = result

func choose_option(value):
	emit_signal("option_chosen", value)

func _on_StatAdjustButton_pressed():
	var stats:Character = Character.new()
	if stats_are_valid():
		stats.set_snapshot(ranger_data["stats"],1)
	if appearance_data_is_valid():
		stats.name = ranger_data["appearance"].name
	else:
		stats.name = "???"		
	var result = yield(show_stat_adjust_menu(stats), "completed")
	if result:
		load_stats(result)
		ranger_data["stats"] = result

func load_stats(result:Dictionary):
	var character = Character.new()	
	if result:
		character.set_snapshot(result,1)
	if not result:
		character.set_snapshot(trainee_base_stats.get_snapshot(),1)
	character.level = 100
	stat_hex.set_stats_for(character, null, null)
