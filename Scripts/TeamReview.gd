extends "res://menus/BaseMenu.gd"

export (Color) var regular_heading_color:Color
export (Color) var bootleg_heading_color:Color
export (int) var max_offers = 10
export (int) var max_team_size = 6

onready var focus_indicator = find_node("FocusIndicator")
onready var focus_indicator_swap_tape = focus_indicator.get_node(NodePath("SwapTape"))
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
var selected_tapes = []

func _ready():	
	move_info_panel.move = null
	
	generate_tape_slots()
	
	for button in selected_tapes:
		button.connect("focus_entered", self, "_on_tape_focus", [button])
		button.connect("pressed", self, "_on_tape_pressed", [button])		

func generate_tape_slots():
	var team = []
	if SaveState.other_data.has("RangerArenaProperties"):
		var current_cup = SaveState.other_data.RangerArenaProperties["CurrentCup"]
		if current_cup == "Debut":				
			team = set_snapshot(SaveState.other_data.RangerArenaProperties["DebutTeam"]) 
		if current_cup == "Remasters":
			team = set_snapshot(SaveState.other_data.RangerArenaProperties["RemastersTeam"])
		if current_cup == "Mix Tapes":
			team = set_snapshot(SaveState.other_data.RangerArenaProperties["MixTapesTeam"])
		if current_cup == "Bootleg":
			team = set_snapshot(SaveState.other_data.RangerArenaProperties["BootlegTeam"])
	for i in team.size():
		var tape = TapeOfferButton.instance()		
		tape.get_child(0).tape = team[i]
		team_tape_grid.add_child(tape)
		selected_tapes.push_back(tape.get_child(0))
	set_team_focus_order()

func set_snapshot(snaps)->Array:
	var result:Array = []
	for snap in snaps:
		var monster_tape:MonsterTape = MonsterTape.new()
		monster_tape.set_snapshot(snap, 1)
		result.push_back(monster_tape)
	return result	
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


func grab_focus():
	if current_button:
		current_button.grab_focus()
	else :
		selected_tapes[0].grab_focus()
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
	if yield(MenuHelper.confirm("Done reviewing team?"),"completed"):
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
			cancel()				
	
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
