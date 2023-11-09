extends Action
class_name ShowReviewTeamAction

func _run():
	var scene = load("res://mods/RangerArena/UI/TeamReview.tscn")
	var menu = scene.instance()
	MenuHelper.add_child(menu)
	yield (menu.run_menu(), "completed")
	menu.queue_free()
	return true
	

