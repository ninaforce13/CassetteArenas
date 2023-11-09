extends TapeConfig
class_name CustomRangerTapeConfig

export (Dictionary) var tape_snapshot 
var remaster_only:bool = false
var debut_only:bool = false
var rangerdata = load("res://mods/RangerArena/JSON/RangerDataParser.gd")
func _generate_tape(_rand:Random, _defeat_count:int)->MonsterTape:
	var tape = MonsterTape.new()
	if tape_snapshot:
		tape_snapshot = rangerdata.get_custom_monster(tape_snapshot)

	tape.set_snapshot(tape_snapshot, 1)
	if debut_only:
		var new_form = revert_remaster(tape)
		if new_form != tape.form:
			tape.form = new_form
			tape.type_native = new_form.elemental_types			
			regenerate_tape_moves(tape)
	if remaster_only:
		var new_form = remaster_form(tape)
		if new_form != tape.form:
			tape.form = new_form
			tape.type_native = new_form.elemental_types
			regenerate_tape_moves(tape)		
	if type_override.size() > 0 and tape.type_override.size() == 0:
		tape.type_override = type_override.duplicate()
	return tape

func _configure_tape(_tape:MonsterTape, _rand:Random, _value:int):
	pass

func regenerate_tape_moves(tape:MonsterTape):
	var index:int = 0
	for _sticker in tape.stickers:
		tape.peel_sticker(index)
		index += 1
	tape.assign_initial_stickers(false)		
	tape.set_grade(0)
	tape.upgrade_to(5, Random.new(), true)
	tape.fix_slot_overflow(true)	

func get_starters()->Array:
	var forms = Datatables.load("res://data/monster_forms/").table.values()
	var result = []
	var evolutions = []
	for form in forms:
		if form.evolutions.size() > 0:
			result.push_back(form)
			for evo in form.evolutions:
				evolutions.push_back(evo)
	for evo in evolutions:
		result.erase(evo.evolved_form)
	return result

func get_full_remasters()->Array:
	var forms = Datatables.load("res://data/monster_forms/").table.values()
	var result = []
	var evolutions = []
	for form in forms:
		if form.evolutions.size() == 0:
			evolutions.push_back(form)
	for evolution in evolutions:
		for form in forms:			
			for evolved_form in form.evolutions:
				if evolved_form.evolved_form == evolution:
					result.push_back(evolution) 		
	
	return result	

func get_all_forms()->Array:
	return Datatables.load("res://data/monster_forms/").table.values()	

func revert_remaster(tape)->MonsterForm:
	var basicform = tape.form
	var global_forms = get_all_forms()
	if tape.form == null:
		var forms = get_starters()
		basicform = forms[randi() % forms.size()]		
		return basicform
	if tape.form.evolutions.size() == 0:
		for form in global_forms:
			if form.evolutions.size() > 0:
				for evo in form.evolutions:
					if evo.evolved_form == basicform:				
						basicform = form
						break
		for form in global_forms:
			if form.evolutions.size() > 0:
				for evo in form.evolutions:
					if evo.evolved_form == basicform:
						basicform = form
						break
		
		if basicform == tape.form:
			var forms = get_starters()
			basicform = forms[randi() % forms.size()]
	return basicform	

func remaster_form(tape)->MonsterForm:
	var global_forms = get_all_forms()
	var forms = get_full_remasters()
	if tape.form == null:
		return forms[randi() % forms.size()]			 
	var remastered_form
	
	for form in global_forms:			
		for evolved_form in form.evolutions:
			if evolved_form.evolved_form == tape.form:
				remastered_form = tape.form
				break 		
	if remastered_form == null:
		return forms[randi() % forms.size()]
		
	return remastered_form	
