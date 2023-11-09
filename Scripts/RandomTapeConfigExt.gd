extends RandomTapeConfig
var StickerGenerator = preload("res://mods/RangerArena/Scripts/StickerGenerator.gd")
func _generate_tape(encounter_rand:Random, defeat_count:int)->MonsterTape:
	var tape = ._generate_tape(encounter_rand, defeat_count)
	
	var rand:Random
	if not seeded:
		rand = Random.new()
	else :
		if seed_key == "":
			rand = encounter_rand
		else :
			rand = encounter_rand.get_child(seed_key)
	
	if form:
		assert (tape.form != null)
	if tape.form == null:
		tape.form = _rand_form(rand)
	
	if rand.rand_bool(profile_evolution_rate):
		var evos = []
		for evolution in tape.form.evolutions:
			if not evolution.is_secret:
				evos.push_back(evolution.evolved_form)
		if evos.size() > 0:
			tape.form = rand.choice(evos)
	
	if tape.type_override.size() == 0 and bootleg_rate > 0.0 and rand.rand_float() < bootleg_rate:
		tape.type_override = [BattleSetupUtil.random_type(rand)]
	StickerGenerator.configure_stickers(tape)
	return tape

func _configure_tape(tape:MonsterTape, rand:Random, exp_points:int):
	pass
