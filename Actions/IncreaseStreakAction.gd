extends Action
class_name IncreaseStreakAction
export (int) var increment = 1

func run():
	var current_cup = SaveState.other_data.RangerArenaProperties["CurrentCup"]
	if current_cup == "Debut":
		SaveState.other_data.RangerArenaProperties["DebutStreak"] += increment	
	if current_cup == "Remasters":
		SaveState.other_data.RangerArenaProperties["RemastersStreak"] += increment		
	if current_cup == "Mix Tapes":
		SaveState.other_data.RangerArenaProperties["MixTapesStreak"] += increment
	if current_cup == "Bootleg":
		SaveState.other_data.RangerArenaProperties["BootlegStreak"] += increment									
	return true


