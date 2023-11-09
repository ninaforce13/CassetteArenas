extends DecoratorAction
class_name CheckCustomRangerCountAction

export (bool) var always_succeed:bool = false
export (bool) var invert:bool = false
var rangerdata = preload("res://mods/RangerArena/JSON/RangerDataParser.gd")
func conditions_met()->bool:
	if root == null:
		setup()
	return check_conditions(self)

func check_conditions(_conds)->bool:		  
	var files = rangerdata.get_files(rangerdata.get_directory())
	var recruits = rangerdata.read_json(files)
	return (recruits.size() >= 2) if not invert else (recruits.size() < 2)

func run():
	if not conditions_met():
		return always_succeed
	return .run()

