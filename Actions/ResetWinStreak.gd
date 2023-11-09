extends Action
class_name ResetWinStreak
export (bool) var reset_current_cup = true
export (String) var reset_stat = "DebutStreak"

func run():
	if reset_current_cup:
		var current_cup = SaveState.other_data.RangerArenaProperties["CurrentCup"]
		if current_cup == "Debut":
			SaveState.other_data.RangerArenaProperties["DebutStreak"] = 0		
			SaveState.set_flag("debut_inprogress", false)
		if current_cup == "Remasters":
			SaveState.other_data.RangerArenaProperties["RemastersStreak"] = 0
			SaveState.set_flag("remasters_inprogress", false)
		if current_cup == "Mix Tapes":
			SaveState.other_data.RangerArenaProperties["MixTapesStreak"] = 0
			SaveState.set_flag("mixtapes_inprogress", false)
		if current_cup == "Bootleg":
			SaveState.other_data.RangerArenaProperties["BootlegStreak"] = 0
			SaveState.set_flag("bootleg_inprogress", false)
		if current_cup == "Custom":
			SaveState.other_data.RangerArenaProperties["CustomStreak"] = 0
			SaveState.set_flag("custom_inprogress", false)
		if SaveState.other_data.RangerArenaProperties.has(current_cup+"Partner1"):
			SaveState.other_data.RangerArenaProperties[current_cup+"Partner1"] = null											
	else:
		SaveState.other_data.RangerArenaProperties[reset_stat] = 0										 		
	return true
