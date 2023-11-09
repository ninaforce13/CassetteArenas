extends DecoratorAction
class_name CheckSaveStateConditionAction

const DEFAULT_REQUIRE_QUEST_STATE:int = 15

export (bool) var always_succeed:bool = false
export (String) var other_data_property = ""
export (String) var other_data_value = ""
export (String) var one_time_flag:String = ""
export (Array, String) var set_flags:Array = []
export (Array, String) var clear_flags:Array = []
export (Array, String) var require_flags:Array = []
export (Array, String) var deny_flags:Array = []


func conditions_met()->bool:
	if root == null:
		setup()
	return check_conditions(self)

func check_conditions(conds)->bool:	
	if not SaveState.other_data.has("RangerArenaProperties"):			
		return false
	if not SaveState.other_data.RangerArenaProperties[other_data_property] == other_data_value:
		return false
	
	
	return true


func run():
	if not conditions_met():
		return always_succeed
	return .run()

func _exit_action(result):
	if result:
		if one_time_flag != "":
			SaveState.set_flag(one_time_flag, true)
		for flag in set_flags:
			SaveState.set_flag(flag, true)
		for flag in clear_flags:
			SaveState.set_flag(flag, false)
