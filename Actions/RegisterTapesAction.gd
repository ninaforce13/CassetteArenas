extends Action
class_name RegisterTapesAction

func _run():
	RegisterTapes()
	return true
	
func RegisterTapes():
	if GetCup() == "Debut":
		SaveState.other_data.RangerArenaProperties["DebutTeam"] = get_snapshot(SaveState.party.get_tapes()) 
	if GetCup() == "Remasters":
		SaveState.other_data.RangerArenaProperties["RemastersTeam"] = get_snapshot(SaveState.party.get_tapes()) 
	if GetCup() == "Mix Tapes":
		SaveState.other_data.RangerArenaProperties["MixTapesTeam"] = get_snapshot(SaveState.party.get_tapes()) 
	if GetCup() == "Bootleg":
		SaveState.other_data.RangerArenaProperties["BootlegTeam"] = get_snapshot(SaveState.party.get_tapes()) 
	if GetCup() == "Custom":
		SaveState.other_data.RangerArenaProperties["CustomTeam"] = get_snapshot(SaveState.party.get_tapes()) 
	if GetCup() == "Triple Threat":
		SaveState.other_data.RangerArenaProperties["TripleThreatTeam"] = get_snapshot(SaveState.party.get_tapes()) 		
func get_snapshot(tapes)->Array:
	var result:Array = []
	for tape in tapes:
		result.push_back(tape.get_snapshot())
	return result

func GetCup():
	return SaveState.other_data.RangerArenaProperties["CurrentCup"]
