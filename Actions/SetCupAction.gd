extends Action
class_name SetCupAction

export(String) var cup_name = "Free Style"

func _run():
	SaveState.other_data.RangerArenaProperties["CurrentCup"] = cup_name
	return true
