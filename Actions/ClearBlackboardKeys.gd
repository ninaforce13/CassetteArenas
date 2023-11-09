extends Action
class_name ClearBlackboardKeys

export (Array,String) var bb_keys:Array = []

func _run():
	for key in bb_keys:
		blackboard.erase(key)
	
	return true
