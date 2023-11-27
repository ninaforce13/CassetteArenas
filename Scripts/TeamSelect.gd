extends "res://menus/BaseMenu.gd"

export (float) var bootleg_rate:float = 0.01
export (float) var rare_sticker_rate:float = 0.05
export (float) var random_sticker_rate:float = 0.35
export (bool) var starters_only = false
export (bool) var full_remasters_only = false
export (Color) var regular_heading_color:Color
export (Color) var bootleg_heading_color:Color
export (int) var max_offers = 10
export (int) var max_team_size = 6

onready var focus_indicator = find_node("FocusIndicator")
onready var focus_indicator_swap_tape = focus_indicator.get_node(NodePath("SwapTape"))
onready var tape_offer_grid = get_node("Scroller/OverscanMarginContainer/HBoxContainer/TapeUI/TapeOptions/PanelContainer/ScrollContainer/GridContainer")
onready var team_tape_grid = get_node("Scroller/OverscanMarginContainer/HBoxContainer/TapeUI/SelectedTeam/PanelContainer/ScrollContainer/GridContainer")
onready var tape_name_label = find_node("TapeNameLabel")
onready var grade_stars = find_node("GradeStars")
onready var type_labels = find_node("TypeLabels")
onready var ap_bar = find_node("APBar")
onready var hp_bar = find_node("HPBar")
onready var sprite_container = find_node("MonsterSpriteContainer")
onready var stat_hex = find_node("StatHex")
onready var stickers_grid = find_node("Stickers")
onready var move_info_panel = find_node("MoveInfoPanel")
onready var heading_panels = [
	find_node("HeadingPanel1"), 
	find_node("HeadingPanel2"),
	find_node("HeadingPanel3")	 
]

const MoveButton = preload("res://battle/ui/MoveButton.tscn")
const TapeOfferButton = preload("res://mods/RangerArena/UI/TapeOffering.tscn")
const ExtraSlot = preload("res://data/sticker_attributes/extra_slot.tres")

var current_sticker_button = null
var swapping_tape:MonsterTape = null
var swapping_tape_button = null
var current_button = null
var tape_offers = []
var selected_tapes = []

func _ready():
	var monster_forms 
	if starters_only:
		monster_forms = get_starters()
	elif full_remasters_only:
		monster_forms = get_full_remasters()
	else:
		monster_forms = Datatables.load("res://data/monster_forms/").table.values()
	move_info_panel.move = null
	monster_forms = filter_forms(monster_forms)
	generate_tape_slots()
	
	for button in tape_offers:
		var form = monster_forms[randi()%monster_forms.size()]
		var monster_tape = generate_tape(form)			
		button.tape = monster_tape
		button.connect("focus_entered", self, "_on_tape_focus", [button])
		button.connect("pressed", self, "_on_tape_pressed", [button])

	for button in selected_tapes:
		button.connect("focus_entered", self, "_on_tape_focus", [button])
		button.connect("pressed", self, "_on_tape_pressed", [button])		

func filter_forms(monster_forms)->Array:
	var result:Array = []
	for form in monster_forms:
		if SaveState.species_collection.has_obtained_species(form):
			result.push_back(form)
	return result	

func generate_tape_slots():
	for _i in max_offers:
		var tape_offer = TapeOfferButton.instance()
		tape_offer_grid.add_child(tape_offer)
		tape_offers.push_back(tape_offer.get_child(0))
	
	for _i in max_team_size:
		var empty_tape = TapeOfferButton.instance()		
		team_tape_grid.add_child(empty_tape)
		selected_tapes.push_back(empty_tape.get_child(0))
	
	set_offering_focus_order()
	set_team_focus_order()

func set_offering_focus_order():
	for tape in tape_offer_grid.get_children():
		tape.get_child(0).set_focus_neighbour(MARGIN_BOTTOM, "")
		tape.get_child(0).set_focus_neighbour(MARGIN_LEFT, "")
		tape.get_child(0).set_focus_neighbour(MARGIN_RIGHT, "")
		tape.get_child(0).set_focus_neighbour(MARGIN_TOP, "")
	var last_tape = tape_offer_grid.get_child(tape_offer_grid.get_child_count() - 1).get_child(0)
	var first_tape = tape_offer_grid.get_child(0).get_child(0)
	last_tape.set_focus_neighbour(MARGIN_BOTTOM, first_tape.get_path())
	first_tape.set_focus_neighbour(MARGIN_TOP, last_tape.get_path())

func set_team_focus_order():
	for tape in team_tape_grid.get_children():
		tape.get_child(0).set_focus_neighbour(MARGIN_BOTTOM, "")
		tape.get_child(0).set_focus_neighbour(MARGIN_LEFT, "")
		tape.get_child(0).set_focus_neighbour(MARGIN_RIGHT, "")
		tape.get_child(0).set_focus_neighbour(MARGIN_TOP, "")	
	var last_member = team_tape_grid.get_child(team_tape_grid.get_child_count() - 1).get_child(0)
	var first_member = team_tape_grid.get_child(0).get_child(0)
	last_member.set_focus_neighbour(MARGIN_BOTTOM, first_member.get_path())
	first_member.set_focus_neighbour(MARGIN_TOP, last_member.get_path())		

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

func grab_focus():
	if current_button:
		current_button.grab_focus()
	else :
		tape_offers[0].grab_focus()

func generate_tape(form)->MonsterTape:
	var result = MonsterTape.new()
	result.set_form(form)
	result.assign_initial_stickers(true)
	result.upgrade_to(5, Random.new())	
	
	var maxslots = form.move_slots
	var extra_slots:int = 0
	for upgrade in form.tape_upgrades:
		if upgrade is TapeUpgradeMove:
			if upgrade.add_slot:
				maxslots += 1
				
	if result.stickers.size() > maxslots:			
		var remove_count = result.stickers.size() - maxslots
		for _i in range (remove_count):
			var sticker = result.stickers[randi()%result.stickers.size()]
			result.stickers.erase(sticker)

	var duplicates:Dictionary = {}
	for sticker in result.stickers:
		if duplicates.has(sticker.battle_move):			
			result.stickers.erase(duplicates[sticker.battle_move])
		if not duplicates.has(sticker.battle_move):			
			duplicates[sticker.battle_move] = sticker	
	
	while result.stickers.size() < maxslots:
		var new_sticker:Array = generate_stickers(Random.new(),result.form.move_tags, 1, true)			
		if not duplicates.has(new_sticker[0].battle_move):
			result.stickers.push_back(new_sticker[0])
			duplicates[new_sticker[0].battle_move] = new_sticker[0]
	var new_stickers:Array = []
	for sticker in result.stickers:		
		if random_sticker_applied():		
			var new_sticker:Array  = generate_stickers(Random.new(),result.form.move_tags, 1, true)						
			if not duplicates.has(new_sticker[0].battle_move):			
				duplicates.erase(sticker.battle_move)
				duplicates[new_sticker[0].battle_move] = new_sticker[0]
				sticker = new_sticker[0]
		if rare_sticker_applied() and move_is_upgradable(sticker.battle_move):
			sticker = upgrade_sticker(sticker)
			if rare_sticker_applied() and move_is_upgradable(sticker.battle_move):
				sticker = upgrade_sticker(sticker)
		new_stickers.push_back(sticker)

	for sticker in new_stickers:
		for attribute in sticker.attributes:			
			if attribute.get_script() == ExtraSlot.get_script():
				extra_slots += 1
	while extra_slots > 0:		
		var new_sticker:Array  = generate_stickers(Random.new(),result.form.move_tags, 1, false)	
		if duplicates.has(new_sticker[0].battle_move):	
			continue
		for attribute in new_sticker[0].attributes:
			if attribute.get_script() == ExtraSlot.get_script():
				extra_slots += 1											
		new_stickers.push_back(new_sticker[0])
		duplicates[new_sticker[0].battle_move] = new_sticker[0]
		extra_slots -= 1
	
	var has_attack:bool = false
	for sticker in new_stickers:
		if sticker.battle_move.power > 0:
			has_attack = true
			break		

	while not has_attack:
		var new_sticker:Array = generate_stickers(Random.new(),result.form.move_tags, 1, false)						
		if not duplicates.has(new_sticker[0].battle_move) and new_sticker[0].battle_move.power > 0:			
			new_stickers.remove(randi()%new_stickers.size())
			new_stickers.push_back(new_sticker[0])
			has_attack = true
			
		
	result.stickers = new_stickers.duplicate()
		
	
	if bootleg_tape_applied():
		result.type_override = [BattleSetupUtil.random_type(Random.new())]
	
	return result

func move_is_upgradable(move:BattleMove)->bool:
	return move.attribute_profile != null

func random_sticker_applied()->bool:
	return randf() < random_sticker_rate

func bootleg_tape_applied()->bool:
	return randf() < bootleg_rate

func rare_sticker_applied()->bool:
	return randf() < rare_sticker_rate

func upgrade_sticker(sticker):
	return ItemFactory.upgrade_rarity(sticker, Random.new())

func _on_tape_focus(button):
	current_button = button
	update_ui(button.tape)
	set_sticker_focus_order()
func update_ui(tape):	
	if tape_name_label and tape:
		var bootleg = tape.type_override.size() > 0
		for heading_panel in heading_panels:
			heading_panel.get_stylebox("panel").bg_color = bootleg_heading_color if bootleg else regular_heading_color
		
		tape_name_label.text = tape.get_name()
		grade_stars.set_grade(tape.grade)
		type_labels.tape = tape
		var form = tape.create_form()
		ap_bar.value = form.max_ap
		ap_bar.max_value = form.max_ap
		sprite_container.set_form(form)
		stat_hex.set_stats_for(null, tape)	

		var sticker_slots = tape.get_max_stickers()
		while stickers_grid.get_child_count() > sticker_slots:
			var button = stickers_grid.get_child(stickers_grid.get_child_count() - 1)
			var focus = button.has_focus()
			stickers_grid.remove_child(button)
			button.queue_free()
			if focus:
				if stickers_grid.get_child_count() > 0:
					stickers_grid.get_child(0).grab_focus()
				else :
					stickers_grid.grab_focus()
			if current_sticker_button == button:
				if stickers_grid.get_child_count() > 0:
					current_sticker_button = stickers_grid.get_child(0)
				else :
					current_sticker_button = null
#
		while stickers_grid.get_child_count() < sticker_slots:
			var button = MoveButton.instance()
			button.show_type_icon = true
			button.connect("focus_entered", self, "_on_MoveButton_focus_entered", [button, tape])
			stickers_grid.add_child(button)
#
		for i in range(sticker_slots):
			var sticker = tape.stickers[i] if i < tape.stickers.size() else null
			var button = stickers_grid.get_child(i)
			button.tape = tape
			assert (sticker is StickerItem or sticker is BattleMove or sticker == null)
			button.move = sticker.get_modified_move() if sticker is StickerItem else sticker
			
		
		_on_MoveButton_focus_entered(stickers_grid.get_child(0), tape)

func set_sticker_focus_order():
	for sticker in stickers_grid.get_children():
		sticker.set_focus_neighbour(MARGIN_BOTTOM, "")
		sticker.set_focus_neighbour(MARGIN_TOP, "")
	var last_sticker = stickers_grid.get_child(stickers_grid.get_child_count() - 1)
	var first_sticker = stickers_grid.get_child(0)
	last_sticker.set_focus_neighbour(MARGIN_BOTTOM, first_sticker.get_path())
	first_sticker.set_focus_neighbour(MARGIN_TOP, last_sticker.get_path())	

func generate_stickers(rand:Random, sticker_tags, max_num:int = - 1, suppress_upgrade:bool = false)->Array:
	var stickers = []
	var moves:Array = []
	for tag in sticker_tags:
		moves += BattleMoves.get_moves_for_tag(tag)
	
	assert (moves.size() > 0)
	if moves.size() == 0:
		return []
	
	for _i in range(max_num):
		if moves.size() == 0:
			break
		var move = rand.choice(moves)
		moves.erase(move)
		var item = ItemFactory.generate_item(move, rand)
		assert (item != null)
		
		if rare_sticker_applied() and not suppress_upgrade and move_is_upgradable(move):
			item = ItemFactory.upgrade_rarity(item, rand)
			assert (item != null)
			assert (item.rarity >= BaseItem.Rarity.RARITY_UNCOMMON)
		
		stickers.push_back(item)
	
	return stickers	

func _on_MoveButton_focus_entered(button, tape):
	current_sticker_button = button
	move_info_panel.fighter_types = tape.get_types()
	move_info_panel.set_move(button.move)
	move_info_panel.rect_min_size.y = max(move_info_panel.rect_min_size.y, move_info_panel.rect_size.y)

func start_swapping(tape_button):
	assert (tape_button != null)
	swapping_tape = tape_button.tape
	swapping_tape_button = tape_button
	focus_indicator_swap_tape.visible = true
	focus_indicator_swap_tape.tape = swapping_tape
	tape_button.tape = null

func end_swapping():
	assert (swapping_tape != null)
	assert (swapping_tape_button != null)
	swapping_tape = null
	focus_indicator_swap_tape.visible = false
	focus_indicator_swap_tape.tape = null

func _on_tape_pressed(_input):
	if swapping_tape:
		swapping_tape_button.tape = current_button.tape
		current_button.tape = swapping_tape	
		end_swapping()
		sort_tapes()
		set_offering_focus_order()
		set_team_focus_order()		
		current_button.grab_focus()
		return
			
	if current_button.form == null:
		return

	if not swapping_tape:
		start_swapping(current_button)
		current_button.grab_focus()

func sort_tapes():
	var sorted_tapes = []
	sorted_tapes = tape_offer_grid.get_children().duplicate()		
	sorted_tapes.sort_custom(self, "_sort_empty_last")	
	
	for i in range (sorted_tapes.size()):
		var node = sorted_tapes[i]
		tape_offer_grid.move_child(node, i)
	
	sorted_tapes = team_tape_grid.get_children().duplicate()
	sorted_tapes.sort_custom(self, "_sort_empty_last")
	
	for i in range (sorted_tapes.size()):
		var node = sorted_tapes[i]
		team_tape_grid.move_child(node, i)
	
static func _sort_empty_last(a, b):
	if a.get_child(0).tape != null and b.get_child(0).tape == null:
		return true		
	return false
	
func _on_Confirm_pressed():
	var team_count = 0
	var team = []
	for slot in team_tape_grid.get_children():
		if slot.get_child(0).tape != null:
			team_count += 1
			team.append(slot.get_child(0).tape)
	if team_count == max_team_size:
		if yield(MenuHelper.confirm("Take these tapes into the Arena?"),"completed"):
			if SaveState.other_data.has("RangerArenaProperties"):
				var current_cup = SaveState.other_data.RangerArenaProperties["CurrentCup"]
				if current_cup == "Debut":				
					SaveState.other_data.RangerArenaProperties["DebutTeam"] = get_snapshot(team)
				if current_cup == "Remasters":
					SaveState.other_data.RangerArenaProperties["RemastersTeam"] = get_snapshot(team)
				if current_cup == "Mix Tapes":
					SaveState.other_data.RangerArenaProperties["MixTapesTeam"] = get_snapshot(team)
				if current_cup == "Bootleg":
					SaveState.other_data.RangerArenaProperties["BootlegTeam"] = get_snapshot(team)	
				if current_cup == "Custom":
					SaveState.other_data.RangerArenaProperties["CustomTeam"] = get_snapshot(team)									
				cancel()				
	if team_count < max_team_size:
		yield (GlobalMessageDialog.show_message("You only have " +str(team_count)+"/"+str(max_team_size) + " tapes. A full team is required.", true, true), "completed")
func _process(_delta):
	focus_indicator.hide_when_focus_lost = not selected_tapes.has(current_button)

func get_snapshot(tapes)->Array:
	var result:Array = []
	for tape in tapes:
		result.push_back(tape.get_snapshot())
	return result
func _on_InfoPanel_pressed():
	if stickers_grid.get_children().size() > 0:
		if current_sticker_button.has_focus():
			current_button.grab_focus()
		else:			
			stickers_grid.get_child(0).grab_focus()
