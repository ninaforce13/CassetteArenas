extends Action
export (String, "Debut","Remasters","Mix Tapes","Bootleg","Custom") var cup
class_name ShowPartnerSelectMenuAction

export (String) var set_flag = "partner_selected"
func _run():
	var scene = load("res://mods/RangerArena/UI/PartnerSelectScreen.tscn")
	var menu = scene.instance()
	MenuHelper.add_child(menu)
	var result = yield (menu.run_menu(), "completed")
	menu.queue_free()
	SaveState.set_flag(set_flag, result != null)
	if result:
		SaveState.other_data.RangerArenaProperties[cup+"Partner1"] = result
	return true
	


