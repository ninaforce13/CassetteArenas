extends "res://menus/BaseMenu.gd"

enum value_range {MINIMUM = 0, AVERAGE = 1, MAX = 2}

signal show_tape_actions
signal show_sticker_actions
export (Color) var regular_heading_color:Color
export (Color) var bootleg_heading_color:Color

const TapeStorageButton = preload("res://menus/tape_storage/TapeStorageButton.tscn")
const TapeActionButtons = preload("AssignmentActionButtons.tscn")
const MoveButton = preload("res://battle/ui/MoveButton.tscn")
const PartyStickerActionButtons = preload("res://mods/RangerArena/JSON/AssignmentStickerActions.tscn")
const MoveButtonScript = preload("res://battle/ui/MoveButton.gd")
const StickerInventory = preload("StickerInventoryMenu.tscn")
const CompatibilityAttribute = preload("res://data/sticker_attributes/compatibility.tres")
class Category:
	extends Reference
	
	var name:String
	var tapes_getter:Bind
	
	func _init(name:String = "", tapes_getter:Bind = null):
		self.name = name
		self.tapes_getter = tapes_getter

onready var title_label = find_node("TitleLabel")
onready var tape_buttons = find_node("TapeButtons")
onready var empty_label = find_node("EmptyLabel")
onready var tape_ui = find_node("MonsterPreview")
onready var action_buttons_parent = find_node("ActionButtonsParent")
onready var tape_button_scroll = find_node("TapeButtonScroll")
onready var tape_name_label = find_node("TapeNameLabel")
onready var grade_stars = find_node("GradeStars")
onready var favorite = find_node("FavoriteIcon")
onready var type_labels = find_node("TypeLabels")
onready var ap_bar = find_node("APBar")
onready var hp_bar = find_node("HPBar")
onready var sprite_container = find_node("MonsterSpriteContainer")
onready var stat_hex = find_node("StatHex")
onready var stickers_grid = find_node("Stickers")
onready var move_info_panel = find_node("MoveInfoPanel")
onready var buttons = find_node("Buttons")
onready var cancelbtn = find_node("CancelButton")
onready var heading_panels = [
	find_node("HeadingPanel1"), 
	find_node("HeadingPanel2"),
	find_node("HeadingPanel3")	 
]
onready var sticker_actions_parent = find_node("StickerActionsParent")
onready var sticker_focus_indicator = find_node("StickerFocusIndicator")
onready var stickers = find_node("Stickers")
var tape:MonsterTape
var applying_sticker:StickerItem = null
var swapping_sticker_button
var current_sticker_button
var categories:Array
var category_index:int setget set_category_index
var current_tapes:Array
var current_tape:MonsterTape setget set_current_tape
var current_button:Button

var assigned_tapes:Array
var tapes_by_type:Dictionary
var tapes_by_name:Array
var tapes_by_index:Array
var load_tapes:Dictionary 
var rangerdata = preload("res://mods/RangerArena/JSON/RangerDataParser.gd")
func _ready():

	build_tape_list()
	set_current_tape(null)
	
	categories.push_back(Category.new("Assigned Tapes", Bind.new(self, "_get_party_tapes")))
	categories.push_back(Category.new("Sort: Name", Bind.new(self, "_get_all_tapes_by_name")))
	categories.push_back(Category.new("Sort: Index", Bind.new(self, "_get_all_tapes_by_number")))
	
	var types = Datatables.load("res://data/elemental_types").table.values().duplicate()
	
	for type in types:
		categories.push_back(Category.new("Filter: " + Loc.tr(type.name), Bind.new(self, "_get_tapes_of_type", [type])))
	if load_tapes:
		assign_loaded_tapes(load_tapes)
	set_category_index(1)
	

func assign_loaded_tapes(result:Dictionary):
	for key in result.keys():
		var tape = MonsterTape.new()
		result[key] = rangerdata.get_custom_monster(result[key])
		tape.set_snapshot(result[key], 1)
		assigned_tapes.push_back(tape)

func build_tape_list():
	var monster_forms = Datatables.load("res://data/monster_forms/").table.values()
	for form in monster_forms:
		var tape = MonsterTape.new()
		tape.set_form(form)
		tape.assign_initial_stickers(false)
		tape.upgrade_to(5, Random.new(), true)
		tape.fix_slot_overflow(true)
		var index = tapes_by_name.bsearch_custom(tape, self, "_cmp_tape_by_name", false)
		tapes_by_name.insert(index, tape)
				
		index = tapes_by_index.bsearch_custom(tape, self, "_cmp_tape_by_index", false)
		tapes_by_index.insert(index, tape)
		
		for type in tape.get_types():
			var type_coll = _get_tapes_of_type(type)
			index = type_coll.bsearch_custom(tape, self, "_cmp_tape_by_name", false)
			type_coll.insert(index, tape)

func regenerate_tape_moves(tape:MonsterTape):
	var battle_moves:Array = BattleMoves.get_compatible_moves(tape, false)	
	tape.stickers = []	
	tape.assign_initial_stickers(false)
	while tape.stickers.size() < tape.get_max_stickers():
		var move = battle_moves[randi()%battle_moves.size()]
		var rarity = tape.rand_sticker_rarity(false, null)
		tape.stickers.push_back(ItemFactory.create_sticker(move, null, rarity))
	
func shown():
	.shown()

func grab_focus():
	tape_buttons.grab_focus()

func _get_party_tapes()->Array:
	return assigned_tapes

func _get_all_tapes_by_name()->Array:
	return tapes_by_name

func _get_all_tapes_by_number()->Array:
	return tapes_by_index

func set_category_index(value:int):
	category_index = int(clamp(value, 0, categories.size() - 1))
	update_ui()

func _get_tapes_of_type(type:ElementalType)->Array:
	if not tapes_by_type.has(type.id):
		tapes_by_type[type.id] = []
	return tapes_by_type[type.id]

func _cmp_tape_by_name(a:MonsterTape, b:MonsterTape)->bool:
	var a_name = tr(a.get_name())
	var b_name = tr(b.get_name())
	if a_name == b_name:
		return a.grade > b.grade
	return a_name < b_name

func _cmp_tape_by_index(a:MonsterTape, b:MonsterTape)->bool:
	var ia = a.form.bestiary_index
	var ib = b.form.bestiary_index
	if ia == ib:
		return a.grade > b.grade
	elif ia == - 1 and ib == - 1:
		return false
	elif ia == - 1:
		return false
	elif ib == - 1:
		return true
	else :
		return ia < ib

func update_ui():
	if not title_label:
		return 
	var category = categories[category_index]
	title_label.text = category.name
	setup_tape_buttons(category.tapes_getter.call_func())
	stickers.setup_focus()

func change_category(direction:int):
	var focus_owner =  get_focus_owner()
	if focus_owner.get_script() == MoveButtonScript:
		return
	set_category_index(posmod(category_index + direction, categories.size()))
	tape_buttons.grab_focus()

func setup_tape_buttons(tapes:Array):
	current_tapes = tapes
	
	for child in tape_buttons.get_children():
		tape_buttons.remove_child(child)
		child.queue_free()
	
	current_button = null
	for tape in tapes:
		var button = TapeStorageButton.instance()
		button.tape = tape
		tape_buttons.add_child(button)
		button.connect("focus_entered", self, "_on_focus_entered", [button, tape])
		button.connect("pressed", self, "show_actions", [button])
		if tape == current_tape:
			current_button = button
	
	empty_label.visible = tape_buttons.get_child_count() == 0
	if current_button:
		tape_buttons.initial_focus = tape_buttons.get_path_to(current_button)
	else :
		tape_buttons.initial_focus = NodePath()
	tape_buttons.setup_focus()
	if tape_buttons.get_child_count() == 0:
		set_current_tape(null)

func _on_focus_entered(button, tape:MonsterTape):
	current_button = button
	set_current_tape(tape)

func set_current_tape(value:MonsterTape):
	current_tape = value
	if not tape_ui:
		return 

	update_monster_preview(value)
	
func update_monster_preview(tape):	
	if tape_name_label and tape:
		var bootleg = tape.type_override.size() > 0
		for heading_panel in heading_panels:
			heading_panel.get_stylebox("panel").bg_color = bootleg_heading_color if bootleg else regular_heading_color
		
		tape_name_label.text = tape.get_name()
		grade_stars.set_grade(tape.grade)
		favorite.visible = tape.favorite
		type_labels.tape = tape
		var form = tape.create_form()
		ap_bar.value = form.max_ap
		ap_bar.max_value = form.max_ap
		sprite_container.set_form(form)
		stat_hex.set_stats_for(null, tape)	

		var sticker_slots = tape.get_max_stickers()
		var sticker_count:int = 0
		while stickers_grid.get_child_count() > sticker_slots:
			var button = stickers_grid.get_child(stickers_grid.get_child_count() - 1)
			var focus = button.has_focus()
			stickers_grid.remove_child(button)
#			tape.peel_sticker(tape.stickers[sticker_count])		
#			tape.fix_slot_overflow()	
			button.queue_free()
			if focus:
				if stickers_grid.get_child_count() > 0:
					stickers_grid.get_child(0).grab_focus()
				else :
					stickers_grid.grab_focus()
			sticker_count += 1
			
		while stickers_grid.get_child_count() < sticker_slots:
			var button = MoveButton.instance()
			button.show_type_icon = true
			button.connect("focus_entered", self, "_on_MoveButton_focus_entered", [button])
			stickers_grid.add_child(button)
			button.connect("pressed", self, "_on_MoveButton_pressed", [button])
			tape.insert_sticker(tape.stickers.size(), null)
			tape.fix_slot_overflow()
#
		for i in range(sticker_slots):
			var sticker = tape.stickers[i] if i < tape.stickers.size() else null
			var button = stickers_grid.get_child(i)
			button.tape = tape
			assert (sticker is StickerItem or sticker is BattleMove or sticker == null)
			button.move = sticker.get_modified_move() if sticker is StickerItem else sticker
	
	if not tape:
		tape_name_label.text = "???"
		grade_stars.set_grade(0)
		favorite.visible = false
		type_labels.tape = null
		
		ap_bar.value = 0
		ap_bar.max_value = 0
		sprite_container.set_form(null)
		stat_hex.set_stats_for(null, null)			
		
		var sticker_slots = 0
		while stickers_grid.get_child_count() > sticker_slots:
			var button = stickers_grid.get_child(stickers_grid.get_child_count() - 1)
			var focus = button.has_focus()
			stickers_grid.remove_child(button)
			button.queue_free()
	if stickers_grid:
		stickers_grid.setup_focus()
func show_actions(button):
	emit_signal("show_tape_actions")
	cancelbtn.detect_action = false
	current_button = button
	current_tape = button.tape
	assert (current_tape != null)
	var buttons = TapeActionButtons.instance()
	buttons.tape = current_tape
	buttons.is_party = category_index == 0
	action_buttons_parent.add_child(buttons)
	buttons.connect("option_chosen", self, "_on_ActionButtons_option_chosen")
	buttons.grab_focus()
	tape_buttons.focus_on_hover = false

func _on_ActionButtons_option_chosen(option):
	var co = null
	cancelbtn.detect_action = true
	if current_tape:
		if option == "add_to_party":
			co = _on_add_to_party_option_chosen(current_tape)
		elif option == "put_away":			
			co = _on_put_away_option_chosen(current_tape)
		elif option == "set_signature":			
			co = _on_set_signature_tape(current_tape)		
		elif option == "edit_stickers":
			_on_edit_stickers_option_chosen()
			return
		elif option == "set_bootleg":
			co = _on_set_bootleg_option_chosen(current_tape)
	if co is GDScriptFunctionState:
		yield (co, "completed")
	
	tape_buttons.focus_on_hover = true
	if current_button:
		current_button.grab_focus()
	
	
func _on_edit_stickers_option_chosen():
	sticker_focus_indicator.set_selection(stickers_grid.get_child(0))
	stickers.grab_focus()
	update_ui()		
	
func _on_put_away_option_chosen(tape):
	if assigned_tapes.has(tape):
		assigned_tapes.erase(tape)
	
	update_ui()	
	update_monster_preview(null)

func _on_add_to_party_option_chosen(tape):
	if slots_full():
		yield (GlobalMessageDialog.show_message("ARENAS_FULL_PARTY_ERROR"), "completed")
		set_category_index(0)
		grab_focus()
		return
	var copied_tape:MonsterTape = MonsterTape.new()
	var snapshot = tape.get_snapshot()
	copied_tape.set_snapshot(snapshot, 1)
	assigned_tapes.push_back(copied_tape)
	
	var slot_occupancy:String = str(6 - assigned_tapes.size()) 
	var slot_message_open:String = str(6 - assigned_tapes.size()) +" slot(s) left."
	var slot_message_full:String = "All slots fufilled."
	var slot_message:String =  slot_message_open if not slots_full() else slot_message_full
	yield (GlobalMessageDialog.show_message(Loc.tr(copied_tape.form.name) + " has been assigned. " + slot_message),"completed")
	if slots_full():
		set_category_index(0)
			
func slots_full()->bool:
	return assigned_tapes.size() >= 6

func _on_set_bootleg_option_chosen(tape):
	var types = Datatables.load("res://data/elemental_types").table.values().duplicate()
	var readable_types:Array = []
	readable_types.push_back("None")
	for type in types:
		readable_types.push_back(type.name)
	var result = yield (GlobalMenuDialog.show_menu(readable_types), "completed")
	if result:		
		tape.type_override = []
		tape.type_override.push_back(types[result-1])
	if not result:
		tape.type_override = []
	regenerate_tape_moves(tape)	
	current_button.set_tape(tape)
	update_monster_preview(tape)

func _on_set_signature_tape(tape):
	if assigned_tapes.has(tape):
		for assigned_tape in assigned_tapes:
			if tape == assigned_tape:
				tape.favorite = true
				assigned_tape.favorite = true
			else:
				assigned_tape.favorite = false
		yield (GlobalMessageDialog.show_message(Loc.tr(tape.form.name) + Loc.tr("ARENAS_SIGNATURE_TAPE_ASSIGNED")),"completed")
		update_monster_preview(tape)

func _unhandled_input(event):
	if not MenuHelper.is_in_top_menu(self):
		return 
		
func get_dictionary()->Dictionary:
	var my_dict:Dictionary = {}
	var team:Array = []
	for tape in assigned_tapes:
		if tape != null:
			team.append(tape)	
	var tape_snapshots: Array = get_snapshot(team)
	var index:int = 0
	for snapshot in tape_snapshots:
		my_dict["tape"+str(index)] = snapshot
		index += 1
	return my_dict 			
	
func get_snapshot(tapes)->Array:
	var result:Array = []
	for tape in tapes:
		result.push_back(tape.get_snapshot())
	return result	

func _on_MoveButton_focus_entered(button):
	current_sticker_button = button
	move_info_panel.fighter_types = current_tape.get_types()
	move_info_panel.move = button.move
	move_info_panel.rect_min_size.y = max(move_info_panel.rect_min_size.y, move_info_panel.rect_size.y)

func _on_MoveButton_pressed(button):
	emit_signal("show_sticker_actions")
	if category_index != 0:
		return
	current_sticker_button = button
	cancelbtn.detect_action = false
	
	if swapping_sticker_button != null:
		current_tape.swap_stickers(swapping_sticker_button.get_index(), current_sticker_button.get_index())
		swapping_sticker_button.modulate.a = 1.0
		swapping_sticker_button = null
		update_ui()
		update_monster_preview(current_tape)
		cancelbtn.detect_action = true
		return 
	
	var buttons = PartyStickerActionButtons.instance()
	buttons.applying_sticker = applying_sticker
	buttons.tape = current_tape
	buttons.sticker_index = button.get_index()
	var rare_count:int = 0
	var uncommon_count:int = 0
	if current_tape.stickers[button.get_index()] != null:
		for attribute in current_tape.stickers[button.get_index()].attributes:
			if attribute.rarity == BaseItem.Rarity.RARITY_UNCOMMON:
				uncommon_count += 1
			if attribute.rarity == BaseItem.Rarity.RARITY_RARE:
				rare_count += 1		
	buttons.rare_full = rare_count >= ItemFactory.MAX_ATTRIBUTES[BaseItem.Rarity.RARITY_RARE]
	buttons.uncommon_full = uncommon_count >= ItemFactory.MAX_ATTRIBUTES[BaseItem.Rarity.RARITY_UNCOMMON]
	buttons.no_effects = rare_count == 0 and uncommon_count == 0
	sticker_actions_parent.add_child(buttons)
	
	buttons.connect("option_chosen", self, "_on_StickerActionButtons_option_chosen")
	buttons.grab_focus()	

func _on_StickerActionButtons_option_chosen(option):
	current_sticker_button.release_focus()
	cancelbtn.detect_action = true
	if option == "move_sticker" and current_sticker_button:
		swapping_sticker_button = current_sticker_button
		swapping_sticker_button.modulate.a = 0.5
		current_sticker_button.grab_focus()
		return 
	
	if option == "peel_sticker" and current_sticker_button:
		yield (peel_sticker(current_sticker_button.get_index()), "completed")
		if current_sticker_button:
			current_sticker_button.grab_focus()
		return 
	
	if option == "apply_sticker" and current_sticker_button:
		var co = apply_sticker(current_sticker_button.get_index())
		if co is GDScriptFunctionState:
			yield (co, "completed")
		current_sticker_button.grab_focus()
		return 
	
	if option == "apply_uncommon" and current_sticker_button:
		var co = apply_effect(current_sticker_button.get_index(),BaseItem.Rarity.RARITY_UNCOMMON)
		if co is GDScriptFunctionState:
			yield (co, "completed")
		current_sticker_button.grab_focus()
		return
		
	if option == "apply_rare" and current_sticker_button:
		var co = apply_effect(current_sticker_button.get_index(), BaseItem.Rarity.RARITY_RARE)
		if co is GDScriptFunctionState:
			yield (co, "completed")
		current_sticker_button.grab_focus()		
		return 		
		
	if option == "remove_effect" and current_sticker_button:
		var co = remove_effect(current_sticker_button.get_index())
		if co is GDScriptFunctionState:
			yield (co, "completed")
		current_sticker_button.grab_focus()		
		return 		
	
	stickers.focus_on_hover = true
	if current_sticker_button:
		current_sticker_button.grab_focus()
	else :
		stickers.grab_focus()	
	
func peel_sticker(index:int, replacement:StickerItem = null):
	assert (replacement == null or replacement is StickerItem)
	var sticker = current_tape.peel_sticker(index, replacement == null)
	if sticker == null:
		return Co.pass()
	if replacement:
		assert (current_tape.stickers[index] == null)
		current_tape.insert_sticker(index, replacement)
	
	update_monster_preview(current_tape)
	return Co.pass()

func apply_sticker(index:int):
	var compatible_any:bool = yield (MenuHelper.confirm("ARENAS_APPLY_COMPATIBLE_EFFECT"),"completed")
	var result = yield (show_sticker_inventory(current_tape, replace_stickers(current_tape,compatible_any), false), "completed")
	if result != null:
		assert (result.item.item is StickerItem)
		if compatible_any:
			apply_compatibility_attribute(result.item.item)		
		if index < current_tape.stickers.size() and current_tape.stickers[index] != null:
			yield (peel_sticker(index, result.item.item), "completed")
		else :
			current_tape.insert_sticker(index, result.item.item)		
	update_monster_preview(current_tape)

func apply_compatibility_attribute(sticker:StickerItem):
	var compatibility = CompatibilityAttribute.instance()	
	sticker.set_attributes([compatibility])
	
func apply_effect(index:int, rarity):
	var attributes = build_sticker_attribute_list()
	var battle_move = current_tape.stickers[index].battle_move
	var attribute_profile = battle_move.attribute_profile
	var readable_options:Array = ["None"]
	var modded_attributes:Array = attributes[attribute_profile]
	var applicable_effects:Array = [null]
	var value_setting = yield(show_options("ARENAS_EFFECT_STRENGTH_PROMPT",["ARENAS_EFFECT_STRENGTH_LOW","ARENAS_EFFECT_STRENGTH_MED","ARENAS_EFFECT_STRENGTH_HIGH"]),"completed")			
	for mod_attribute in modded_attributes:			
		if mod_attribute.rarity == rarity and mod_attribute.is_applicable_to(battle_move):
			if mod_attribute.has_method("generate"):
				mod_attribute.generate(battle_move, Random.new())
				if mod_attribute.get("chance") != null:
					if value_setting == value_range.MINIMUM:					
						mod_attribute.chance = mod_attribute.chance_min
					if value_setting == value_range.AVERAGE:
						mod_attribute.chance = int(mod_attribute.chance_max / 2)
					if value_setting == value_range.MAX:
						mod_attribute.chance = mod_attribute.chance_max
				if mod_attribute.get("stat_value") != null:					
					if value_setting == value_range.MINIMUM:					
						mod_attribute.stat_value = mod_attribute.stat_value_min
					if value_setting == value_range.AVERAGE:
						mod_attribute.stat_value = mod_attribute.stat_value_max / 2
					if value_setting == value_range.MAX:
						mod_attribute.stat_value = mod_attribute.stat_value_max
			readable_options.push_back(mod_attribute.get_description(battle_move))
			applicable_effects.push_back(mod_attribute)
	var result = yield (show_options("ARENAS_EFFECT_PROMPT",readable_options), "completed")
	
	if result > 0:
		current_tape.stickers[index].attributes.push_back(applicable_effects[result])
		current_tape.stickers[index].set_attributes(current_tape.stickers[index].attributes)
				
	update_monster_preview(current_tape)

func remove_effect(index:int):
	var attribute_count:int = 0
	var readable_options:Array = ["None"]
	for attribute in current_tape.stickers[index].attributes:
		var battle_move = current_tape.stickers[index].battle_move	
		readable_options.push_back(attribute.get_description(battle_move))
	
	var result = yield (show_options("ARENAS_REMOVE_EFFECT_PROMPT",readable_options), "completed")
	if result > 0:
		var compatibility_removed:bool = current_tape.stickers[index].attributes[result-1].get_script() == CompatibilityAttribute.get_script()		
		
		current_tape.stickers[index].attributes.remove(result-1)
		current_tape.stickers[index].set_attributes(current_tape.stickers[index].attributes)
		current_tape.fix_slot_overflow(true)
		if not BattleMoves.is_compatible(current_tape, current_tape.stickers[index].battle_move) and compatibility_removed:
			current_tape.peel_sticker(index)
			yield (GlobalMessageDialog.show_message("ARENAS_INCOMPATIBLE_STICKERS_REMOVED"),"completed")							
		
		
	update_monster_preview(current_tape)

func show_options(message:String, options:Array, default_index:int = 0, initial_index:int = 0):
	GlobalMessageDialog.clear_state()
	yield (GlobalMessageDialog.show_message(message, false, false), "completed")
	var result = yield (GlobalMenuDialog.show_menu(options, default_index, initial_index), "completed")
	yield (GlobalMessageDialog.hide(), "completed")
	return result
	
func show_sticker_inventory(context = null, stickers = [], immediate_item_use = false):
	var menu = StickerInventory.instance()
	menu.context = context
	menu.monster_stickers = stickers
	menu.immediate_item_use = false
	MenuHelper.add_child(menu)
	var result = yield (menu.run_menu(), "completed")
	menu.queue_free()
	return result	

func replace_stickers(tape:MonsterTape, compatible_any:bool = false)->Array:
	var battle_moves:Array = BattleMoves.get_compatible_moves(tape, false) 
	if compatible_any:
		var compatibility = CompatibilityAttribute.instance()
		battle_moves = []
		for sticker in BattleMoves.all_stickers:
			if compatibility.is_applicable_to(sticker):
				battle_moves.push_back(sticker)
	var sticker_items:Array = []
	for move in battle_moves:
		var sticker = ItemFactory.create_sticker(move, null, BaseItem.Rarity.RARITY_COMMON)
		sticker.discardable = false
		sticker_items.push_back(sticker)
		sticker_items.sort()
	return sticker_items
func choose_option(value):
	emit_signal("option_chosen", value)


func _on_SaveButton_pressed():
	if yield (MenuHelper.confirm("ARENAS_STICKER_ASSIGN_COMPLETE_PROMPT"),"completed"):
		var tape_dictionary = get_dictionary()
		tape_dictionary = validate_tapes(tape_dictionary)
		choose_option(tape_dictionary)

func validate_tapes(tape_dictionary:Dictionary)->Dictionary:
	var has_favorite:bool = false
									
	for tape_key in tape_dictionary.keys():
		tape_dictionary[tape_key] = rangerdata.set_custom_monster(tape_dictionary[tape_key])
		if tape_dictionary[tape_key].favorite:
			has_favorite = true
			break
	
	if not has_favorite:
		var favorite_key
		for tape_key in tape_dictionary.keys():
			tape_dictionary[tape_key].favorite = true
			favorite_key = tape_key
			break		
	return tape_dictionary


func _on_CancelButton_pressed():
	if swapping_sticker_button != null:
		swapping_sticker_button.modulate.a = 1.0
		swapping_sticker_button = null
		current_sticker_button.grab_focus()
		return		
	var focus_owner = get_focus_owner()	
	if focus_owner.get_script() == MoveButtonScript:
		focus_owner.release_focus()
		tape_buttons.grab_focus()
		return
	if yield (MenuHelper.confirm("ARENAS_TAPE_UNSAVED_WARNING"), "completed"):
		choose_option(null)


func _on_AssignedTapesButton_pressed():
	set_category_index(0)
	if assigned_tapes.size() > 0:
		grab_focus()
		update_monster_preview(assigned_tapes[0])
		
func build_sticker_attribute_list()->Dictionary:
	var types = Datatables.load("res://data/elemental_types").table.values().duplicate()
	var attribute_profiles = Datatables.load("res://data/sticker_attribute_profiles").table.values().duplicate()
	var status_effects = Datatables.load("res://data/status_effects").table.values().duplicate()
	var attribute_dictionary:Dictionary = {}
	for profile in attribute_profiles:
		attribute_dictionary[profile] = []
		for attribute in profile.attributes:			
			var att_instance = attribute.instance()
			if att_instance.get("buffs") != null:				
				for effect in status_effects:
					if effect.is_buff:
						var new_instance = attribute.instance()
						new_instance.buffs = []
						new_instance.buffs.push_back(effect)
						new_instance.chance = new_instance.chance_max
						attribute_dictionary[profile].push_back(new_instance)
				continue
			if att_instance.get("debuffs") != null:
				for effect in status_effects:
					if effect.is_debuff:
						var new_instance = attribute.instance()
						new_instance.debuffs = []
						new_instance.debuffs.push_back(effect)
						new_instance.chance = new_instance.chance_max
						attribute_dictionary[profile].push_back(new_instance)
				continue
			attribute_dictionary[profile].push_back(att_instance)
	return attribute_dictionary	
