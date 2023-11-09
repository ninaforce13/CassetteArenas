extends Action
class_name ShowTeamBuilderAction
export (float) var bootleg_rate = 0.05
export (float) var rare_sticker_rate = 0.05
export (float) var random_sticker_rate = 0.35
export (bool) var starters_only = false
export (bool) var full_remasters_only = false

func _run():
	var scene = load("res://mods/RangerArena/UI/TeamSelect.tscn")
	var menu = scene.instance()
	menu.bootleg_rate = bootleg_rate
	menu.rare_sticker_rate = rare_sticker_rate
	menu.random_sticker_rate = random_sticker_rate
	menu.starters_only = starters_only
	menu.full_remasters_only = full_remasters_only
	MenuHelper.add_child(menu)
	yield (menu.run_menu(), "completed")
	menu.queue_free()
	return true
	

