extends Action
class_name TeamSwapAction

export(bool) var return_team = false
func _run():			
	if not return_team:
		use_rental_tapes()
	if return_team:
		retrieve_player_tapes()

	return true

func use_rental_tapes():
	SaveState.other_data.RangerArenaProperties["SavedTeam"] = SaveState.party.get_tapes().duplicate()
	print("Storing current tapes...")
	debug_team_print(SaveState.other_data.RangerArenaProperties["SavedTeam"], "Stored Tapes:")
	var current_cup = SaveState.other_data.RangerArenaProperties["CurrentCup"]
	var arena_team
	if current_cup == "Debut":				
		arena_team = set_snapshot(SaveState.other_data.RangerArenaProperties["DebutTeam"])
	if current_cup == "Remasters":
		arena_team = set_snapshot(SaveState.other_data.RangerArenaProperties["RemastersTeam"])
	if current_cup == "Mix Tapes":
		arena_team = set_snapshot(SaveState.other_data.RangerArenaProperties["MixTapesTeam"])
	if current_cup == "Bootleg":
		arena_team = set_snapshot(SaveState.other_data.RangerArenaProperties["BootlegTeam"])
	if current_cup == "Free Style":
		arena_team = set_snapshot(SaveState.other_data.RangerArenaProperties["FreeStyleTeam"])	
	if current_cup == "Custom":
		arena_team = set_snapshot(SaveState.other_data.RangerArenaProperties["CustomTeam"])	
	if current_cup == "Triple Threat":
		arena_team = set_snapshot(SaveState.other_data.RangerArenaProperties["TripleThreatTeam"])					
	print("Adding rental tapes...")
	debug_team_print(arena_team, "Rental Tapes:")
	for tape in SaveState.other_data.RangerArenaProperties["SavedTeam"]:
		SaveState.party.remove_tape(tape)
		
	var index = 0	
	for tape in arena_team:
		if index != 1:
			SaveState.party.characters[0].tapes.push_back(tape)
		if index == 1:
			SaveState.party.characters[1].tapes.push_back(tape)
		index += 1
#

func set_snapshot(snaps)->Array:
	var result:Array = []
	for snap in snaps:
		var monster_tape:MonsterTape = MonsterTape.new()
		monster_tape.set_snapshot(snap, 1)
		result.push_back(monster_tape)
	return result

func retrieve_player_tapes():
	
	var current_team = SaveState.party.get_tapes().duplicate()
	var player_team = SaveState.other_data.RangerArenaProperties["SavedTeam"].duplicate()
	print("Returning rental tapes...")
	debug_team_print(current_team, "Rental Tapes:")
	print("Retrieving stored tapes...")
	debug_team_print(player_team, "Retrieved Tapes:")
	var index = 0
	for tape in current_team:
		SaveState.party.remove_tape(tape)		
	for tape in player_team:
		if index != 1:
			SaveState.party.characters[0].tapes.push_back(tape)
		if index == 1:
			SaveState.party.characters[1].tapes.push_back(tape)
		index += 1

func debug_team_print(team:Array, team_type:String):
	var message:String = team_type
	for tape in team:
		message = message + " [" + Loc.tr(tape.form.name) + "], "
	print(message)
