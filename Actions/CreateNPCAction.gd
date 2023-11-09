extends Action
class_name CreateNPCAction

export (String) var set_bb_key:String = "custom_trainee"

func _run():
	var scene = load("res://mods/RangerArena/JSON/RangerRecruiter.tscn")
	var menu = scene.instance()
	MenuHelper.add_child(menu)
	var result = yield (menu.run_menu(), "completed")
	menu.queue_free()
	if result:
		if set_bb_key != "":
			set_bb(set_bb_key, result)			
	return true
