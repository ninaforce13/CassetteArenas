extends MessageDialogAction

export (bool) var use_custom_subs
var current_cup
func _run():
	var audio = self.audio
	if audio == null and use_pawn_sfx_audio != "":
		var pawn = get_pawn()
		if pawn and pawn.get("sfx"):
			var sfx = pawn.sfx.get(use_pawn_sfx_audio)
			if sfx.size() > 0:
				audio = sfx[randi() % sfx.size()]
	
	var dlg = GlobalMessageDialog.message_dialog
	dlg.portrait = portrait
	dlg.portrait_position = portrait_position
	dlg.audio = audio
	dlg.type_sounds = type_sounds
	dlg.font = null
	
	if style == 2:
		dlg.font = preload("res://ui/fonts/archangel/archangel_60.tres")
	elif style == 3:
		dlg.font = preload("res://ui/fonts/archangel/archangel_40.tres")
	
	GlobalMessageDialog.layer = 62 if style != 0 else 64
	
	var subs = create_subs(self)
	
	var variant:int = 0
	if text_variant_seed != "" or blackboard.has("text_variant_seed"):
		var bb_seed = blackboard.get("text_variant_seed", 0)
		if not (bb_seed is int):
			bb_seed = str(bb_seed).hash()
		variant ^= bb_seed
		if text_variant_seed != "":
			variant ^= text_variant_seed.hash()
	else :
		variant = randi()
	
	if SaveState.has_flag("mask_name_" + title):
		dlg.title = "UNKNOWN_NAME"
	else :
		dlg.title = Loc.trvf(title, variant, subs)
	var tape1
	var tape2
	var index = 0  
	for tape in SaveState.party.get_tapes():
		if tape.form is MonsterForm and index == 0:			
			tape1 = Loc.tr(tape.form.description)
		if tape.form is MonsterForm and index == 1:
			tape2 = Loc.tr(tape.form.description)	
			break
		index += 1
	current_cup = SaveState.other_data.RangerArenaProperties["CurrentCup"]
	for i in range(messages.size()):
		var message = messages[i]
		var text
		if use_custom_subs:
			message = Loc.tr(message)
			message = message.replacen("[player]", subs["player"])
			message = message.replacen("[partner]", subs["partner"])		
			message = message.replacen("[tape1]", tape1)		
			message = message.replacen("[tape2]", tape2)	
			message = message.replacen("[ranger_rank]", SaveState.get_ranger_rank())	
			message = message.replacen("[cup]", SaveState.other_data.RangerArenaProperties["CurrentCup"])
			message = message.replacen("[streak]",str(get_win_streak()))	
			
		if use_pronouns != PronounMode.DONT_USE:
			text = Loc.trgvf(message, get_pronouns(), variant, subs)
		else :
			text = Loc.trvf(message, variant, subs)
		
		if style == 2:
			text = SpookyDialog.FORMAT.format([text])
		

		
		
		text = Loc.substitute_mfn(text, SaveState.party.player.pronouns)
		
		if style == 1:
			yield (MenuHelper.show_spooky_dialog(text, audio if i == 0 else null, type_sounds), "completed")
		else :
			yield (GlobalMessageDialog.show_message(text, false, wait_for_confirm or i < messages.size() - 1), "completed")
		
		dlg.audio = null
	
	return true

func get_win_streak()->int:
	if is_debut_cup():
		return SaveState.other_data.RangerArenaProperties["DebutStreak"]
	if is_remasters_cup():
		return SaveState.other_data.RangerArenaProperties["RemastersStreak"]
	if is_bootleg_cup():
		return SaveState.other_data.RangerArenaProperties["BootlegStreak"]	
	if is_mixtapes_cup():
		return SaveState.other_data.RangerArenaProperties["MixTapesStreak"]
	if is_custom_cup():
		return SaveState.other_data.RangerArenaProperties["CustomStreak"]
	return 0
func is_debut_cup()->bool:
	return current_cup == "Debut"

func is_custom_cup()->bool:
	return current_cup == "Custom"

func is_remasters_cup()->bool:
	return current_cup == "Remasters"	

func is_bootleg_cup()->bool:
	return current_cup == "Bootleg"

func is_mixtapes_cup()->bool:
	return current_cup == "Mix Tapes"
