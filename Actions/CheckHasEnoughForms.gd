extends DecoratorAction
class_name CheckHasEnoughForms

export (bool) var always_succeed:bool = false
export (bool) var remasters:bool = false
export (bool) var starters:bool = false
export (bool) var invert:bool = false

func conditions_met()->bool:
	if root == null:
		setup()
	return check_conditions(self)

func check_conditions(_conds)->bool:		  
	var monster_forms = Datatables.load("res://data/monster_forms/").table.values()	
	if starters:
		monster_forms = get_starters()
	if remasters:
		monster_forms = get_full_remasters()	
	
	monster_forms = filter_forms(monster_forms)
	if invert:
		return not monster_forms.size() >= 6	
	return monster_forms.size() >= 6


func filter_forms(monster_forms)->Array:
	var result:Array = []
	for form in monster_forms:
		if SaveState.species_collection.has_obtained_species(form):
			result.push_back(form)
	return result	

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
			forms.erase(form)
	for evolution in evolutions:
		for form in forms:
			for evolved_form in form.evolutions:
				if evolved_form.evolved_form == evolution:
					result.push_back(evolution) 		
	return result	
