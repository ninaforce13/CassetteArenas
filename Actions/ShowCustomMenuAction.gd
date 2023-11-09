extends Action
class_name ShowCustomMenuAction

export (String) var menu_path = ""

func _run():
	var scene = load(menu_path)
	var menu = scene.instance()
	MenuHelper.add_child(menu)
	yield (menu.run_menu(), "completed")
	menu.queue_free()
	return true
	
