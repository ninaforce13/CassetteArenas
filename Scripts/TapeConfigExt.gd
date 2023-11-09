extends TapeConfig
var StickerGenerator = preload("res://mods/RangerArena/Scripts/StickerGenerator.gd")
func _generate_tape(_rand:Random, _defeat_count:int)->MonsterTape:
	var result = MonsterTape.new()
	result.form = form
	result.seed_value = tape_seed_value
	result.type_override = type_override
	if form or type_override.size() > 0 or moves_override.size() > 0:
		
		result.set_meta("raid_no_modify", true)
	StickerGenerator.configure_stickers(result)
	return result

func _configure_tape(tape:MonsterTape, rand:Random, exp_points:int):
	pass
