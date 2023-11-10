extends Action
class_name BattleActionBbkey

export (String) var encounter_name_override:String = ""
export (int, "Failure", "Success") var result_on_player_win:int = 0
export (int, "Failure", "Success") var result_on_player_loss:int = 1
export (int, "Failure", "Success") var result_on_flee:int = 1
export (bool) var disable_fleeing:bool = false
export (bool) var remove_pawn_on_success:bool = false
export (String) var bb_key:String = ""
export (NodePath) var challenger_manager_path
var rangerdata = preload("res://mods/RangerArena/JSON/RangerDataParser.gd")
var customtapeconfig = preload("res://mods/RangerArena/Scripts/CustomRangerTapeConfig.gd")
var customrandomconfig = preload("res://mods/RangerArena/Scripts/CustomRangerRandomTapeConfig.gd")
var StickerGenerator = preload("res://mods/RangerArena/Scripts/StickerGenerator.gd")
var captain_names = ["CAPTAIN_LODESTEIN_NAME_SHORT",	
					"CAPTAIN_JUDAS_NAME_SHORT",	
					"CAPTAIN_HEATHER_NAME_SHORT",	
					"CAPTAIN_SKIP_NAME_SHORT",	
					"CAPTAIN_GLADIOLA_NAME_SHORT",	
					"IANTHE_NAME_SHORT",	
					"RANGER_TRADER_NAME",	
					"CAPTAIN_BUFFY_NAME_SHORT",	
					"CAPTAIN_CLEEO_NAME_SHORT",
					"CAPTAIN_CYBIL_NAME_SHORT",	
					"RANGER_NAME",	
					"CAPTAIN_DREADFUL_NAME_SHORT",	
					"CAPTAIN_WALLACE_NAME_SHORT",	
					"CAPTAIN_ZEDD_NAME_SHORT"]
var challenger_manager
var _removed_pawn:bool = false
var vs_ui = preload("res://mods/RangerArena/UI/BattleTransition.tscn")
func _run():
	challenger_manager = get_node(challenger_manager_path)
	
	var encounter = get_encounter(self, encounter_name_override, bb_key)
	if encounter == null:
		push_error("Couldn't find EncounterConfig for BattleAction")
		return false
	print("Cassette Arenas: Configuring encounter...")
	
	configure_music_overrides(encounter)
	configure_characters(encounter)
	configure_fusion(encounter)
	var config = encounter.get_config()
	var menu = vs_ui.instance()
	configure_transition(menu, config)

	print("Cassette Arenas: Running encounter...")
	MenuHelper.add_child(menu)		
	yield (menu.run_menu(), "completed")
	menu.queue_free()
	var result = yield (_run_encounter(encounter, config), "completed")
	
	return _handle_battle_result(result)

func configure_fusion(encounter:EncounterConfig):
	if has_fusion_setting():
		encounter.enable_ai_fusion = SaveState.other_data.RangerArenaProperties["FusionSet"]
	
func configure_music_overrides(encounter:EncounterConfig):
	if music_mod_override():
		encounter.music_override = load_music()	
		encounter.music_vox_override = load_music()	
	
func has_fusion_setting()->bool:
	return SaveState.other_data.RangerArenaProperties.has("FusionSet")
		
func configure_characters(encounter:EncounterConfig):
	for character in encounter.get_children():
				
		character.level_override = SaveState.party.player.level - 15				
		if captain_names.has(character.character_name) or character.character_name == "CAPTAIN_CODEY_NAME_SHORT":
			character.level_override = SaveState.party.player.level - 5
		
		var frankie_index = 0
		for tape in character.get_children():
			
			if character.character_name == "FRANKIE_NAME" and frankie_index == 0:
				character.base_character.partner_signature_species = tape.form
				var newform = set_frankie_tape()
				if newform:
					tape.form = newform
					character.base_character.partner_signature_species = newform
					
			if challenger_manager.is_bootleg_cup():
#				Respect captain types during bootleg cup. Set as same type bootleg
				if captain_names.has(character.character_name):
					tape.type_override = []
					for type in tape.form.elemental_types:
						tape.type_override.push_back(type)
				else: 	
					tape.type_override = [BattleSetupUtil.random_type(Random.new())]
					
			if challenger_manager.is_debut_cup():				
				if tape is customtapeconfig or tape is customrandomconfig:
					tape.debut_only = true
				else:
					tape.form = challenger_manager.revert_remaster(tape)
					
			if challenger_manager.is_remasters_cup():	
				if tape is customtapeconfig or tape is customrandomconfig:
					tape.remaster_only = true
				else:
					tape.form = challenger_manager.remaster_form(tape)	
				
			if tape is RandomTapeConfig:
				tape.profile_evolution_rate = 0
			
			frankie_index += 1		

func configure_transition(menu, config):
	var index = 0	
	for fighter in config.fighters:
		var characters = fighter.get_characters()
		if SaveState.other_data.RangerArenaProperties.has("Overspill"):					
			fighter.get_controller().disable_overspill_damage = not SaveState.other_data.RangerArenaProperties["Overspill"]		
		 
		if index == 0:
			menu.player3 = characters[0].character
		if index == 1:
			menu.player4 = characters[0].character
		if index == 2:
			menu.player1 = characters[0].character
		if index == 3:
			menu.player2 = characters[0].character
		index += 1
		
func triple_threat()->bool:
	return SaveState.other_data.RangerArenaProperties["CurrentCup"] == "Triple Threat"
	
func set_frankie_tape()->MonsterForm:
	var tape = MonsterTape.new()	
	var form
	var snap_temp = SaveState.other_data.get("frankie_starter")
	var snap
	
	if not snap_temp:
		return null
	if snap_temp:
		snap = snap_temp.duplicate()
	if snap:
		snap = rangerdata.get_custom_monster(snap)

	tape.set_snapshot(snap, snap.get("version", 0))

	form = fully_evolve_tape(tape)
	return form	

func fully_evolve_tape(tape:MonsterTape)->MonsterForm:
	for _i in 2:		
		var selected_evo = null
		for evo in tape.form.evolutions:
			if not evo.is_secret:
				selected_evo = evo
		if selected_evo:
			tape.evolve(selected_evo)	
	return tape.form
	
func music_mod_override()->bool:
	if not SaveState.other_data.has("GramophonePlayerData"):
		return false
	if not SaveState.other_data.GramophonePlayerData.has("BattleData"):
		return false
	return true

func load_music():
	if SaveState.other_data.GramophonePlayerData.BattleData.altload or SaveState.other_data.GramophonePlayerData.BattleData.path == "mute":
		return load_external_ogg(SaveState.other_data.GramophonePlayerData.BattleData.path)
	else:
		return load(SaveState.other_data.GramophonePlayerData.BattleData.path)

func load_external_ogg(path):
	if path == "mute":
		return AudioStreamMP3.new()	
	var ogg_file = File.new()
	var err = ogg_file.open(path, File.READ)
	if err != OK:
		return null
	var bytes = ogg_file.get_buffer(ogg_file.get_len())	
	var stream = AudioStreamMP3.new()	
	stream.data = bytes
	stream.loop = true
	ogg_file.close()
	return stream	

func _handle_battle_result(result):
	var success = false
	if result == 0:
		
		success = result_on_player_win == 1
	elif result == null:
		
		success = result_on_flee == 1
	else :
		
		success = result_on_player_loss == 1
	
	if remove_pawn_on_success and success and not _removed_pawn:
		_removed_pawn = true
		var pawn = get_pawn()
		if pawn:
			if pawn.is_a_parent_of(self):
				detach_root()
			if blackboard.pawn == pawn or (blackboard.pawn and pawn.is_a_parent_of(blackboard.pawn)):
				blackboard.pawn = null
			pawn.get_parent().remove_child(pawn)
			pawn.queue_free()
	
	return success

func get_pawn():
	if values.size() > 0:
		return values[0]
	return .get_pawn()

func _run_encounter(e:EncounterConfig, config):
	if disable_fleeing:
		config.can_flee = false
	config.advantages = blackboard.advantages if blackboard.has("advantages") else []
	return e.run_encounter(config)

static func get_encounter(a:Node, name:String = "", bb_key:String = "")->EncounterConfig:
	if name == "":
		name = "EncounterConfig"
	if a.has_node(name):
		return a.get_node(name) as EncounterConfig	
	if a is Action:
		if a.values.size() > 0 and a.values[0] is EncounterConfig:
			return a.values[0]
		if a.values.size() > 0 and bb_key != "":
			return a.values[0].get_node(name)
		if a.get_pawn().has_node(name):
			return a.get_pawn().get_node(name)
	return null
