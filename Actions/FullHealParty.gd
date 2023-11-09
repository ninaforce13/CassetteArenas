extends Action
class_name FullHealArenaParty

export (bool) var notify_player:bool = true

func _run():	
	SaveState.party.heal()
	
	if notify_player:
		GlobalMessageDialog.clear_state()
		yield (GlobalMessageDialog.show_message("UI_TAPES_REPAIRED"), "completed")
	
	return true
