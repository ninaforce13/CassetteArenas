extends Action
class_name SetArenaOverspillAction
export (bool) var arena_overspill:bool = false

func _run():
	SaveState.other_data.RangerArenaProperties["Overspill"] = arena_overspill
	return true
