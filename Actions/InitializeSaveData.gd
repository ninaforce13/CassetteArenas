extends Action
class_name InitializeSaveDataAction

func run():
	if not SaveState.other_data.has("RangerArenaProperties"):
		SaveState.other_data.RangerArenaProperties = {
													  "SavedTeam":[],
													  "CurrentCup":"",
													  "DebutTeam":[],
													  "RemastersTeam":[],
													  "MixTapesTeam":[],
													  "BootlegTeam":[],
													  "CustomTeam":[],
													  "CustomStreak":0,
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
													  "HealthHandicap":false												  											
													}
	#Added for previous savedata compatability
	if not SaveState.other_data.RangerArenaProperties.has("CustomEncounters"):
		SaveState.other_data.RangerArenaProperties["CustomEncounters"] = []
		SaveState.other_data.RangerArenaProperties["LastCustomFighterIndex"] = -1
		SaveState.other_data.RangerArenaProperties["CustomTeam"] = []
		SaveState.other_data.RangerArenaProperties["CustomStreak"] = 0
		SaveState.other_data.RangerArenaProperties["Overspill"] = false
	if not SaveState.other_data.RangerArenaProperties.has("FusionSet"):
		SaveState.other_data.RangerArenaProperties["FusionSet"] = true
	return true

