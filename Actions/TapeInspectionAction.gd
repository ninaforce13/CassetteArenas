extends DecoratorAction
class_name TapeInspectionAction

export (bool) var always_succeed:bool = false
export (bool) var remasters:bool = false
export (bool) var starters:bool = false
export (bool) var bootlegs:bool = false
export (bool) var invert:bool = false

func conditions_met()->bool:
	if root == null:
		setup()
	return check_conditions(self)

func check_conditions(_conds)->bool:		  
	var tapes = SaveState.party.get_tapes()
	
	if invert:
		return not inspection_passed(tapes)
	return inspection_passed(tapes)


func inspection_passed(tapes)->bool:
	var result:Array = []
	var debut_forms = get_starters()
	var remaster_forms = get_full_remasters()
	for tape in tapes:
		if starters:
			if not debut_forms.has(tape.form):
				return false
		if remasters:
			if not remaster_forms.has(tape.form):
				return false	
		if bootlegs:
			if not tape.type_override.size() > 0:
				return false	
	return true

func run():
	if not conditions_met():
		return always_succeed
	return .run()

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

