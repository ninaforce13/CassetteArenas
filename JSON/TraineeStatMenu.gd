extends "res://menus/BaseMenu.gd"

const STAT_NAMES = ["max_hp", "melee_attack", "melee_defense", "ranged_attack", "ranged_defense", "speed"]

export (Resource) var character:Resource setget set_character
export (int) var total_points = 40
var max_total:int setget set_max_total
var remaining_points:int = 40 setget set_remaining_points

onready var character_name_label = find_node("CharacterNameLabel")
onready var explanation_label = find_node("ExplanationLabel")
onready var remaining_points_label = find_node("RemainingPointsLabel")
onready var stat_hex = find_node("StatHex")
onready var slider_container = find_node("Sliders")
onready var sliders = {
	level = find_node("LevelSlider"), 
	max_hp = find_node("MaxHpSlider"), 
	melee_attack = find_node("MeleeAttackSlider"), 
	melee_defense = find_node("MeleeDefenseSlider"), 
	ranged_attack = find_node("RangedAttackSlider"), 
	ranged_defense = find_node("RangedDefenseSlider"), 
	speed = find_node("SpeedSlider")
}

func _ready():
	if character == null:
		character = Character.new()
	character.level = 100
	var total = total_points
	for stat in STAT_NAMES:
		total += get_default_stat_value(stat)
	set_max_total(total)
	
	set_character(character)

func get_default_stat_value(stat:String)->int:
	var player_template = preload("res://data/characters/player.tres")
	return player_template.get("base_" + stat)

func get_min_stat_value(stat:String)->int:
	if stat == "level":
		return 1
	else:
		return 50

func set_character(value:Resource):
	character = value
	if not character:
		return 
	if character_name_label:
		character_name_label.text = Loc.trf("STAT_ADJUST_MENU_TITLE", {player = character.name})
		
		stat_hex.set_stats_for(character, null)
		for stat in STAT_NAMES:
			var stat_value = character.get_stat(stat, null)
			sliders[stat].set_value(stat_value)
			sliders[stat].min_value = get_min_stat_value(stat)

func set_max_total(value:int):
	max_total = value
	remaining_points = max_total
	if character:
		for stat in STAT_NAMES:
			remaining_points -= character.get_stat(stat, null)
	set_remaining_points(remaining_points)

func set_remaining_points(value:int):
	remaining_points = value
	if remaining_points_label:
		remaining_points_label.text = Loc.trf("STAT_ADJUST_MENU_REMAINING_POINTS", [remaining_points])

func grab_focus():
	slider_container.grab_focus()

func _on_Slider_value_change_requested(stat, delta, new_value):
	if not character:
		return 
	
	var old_value = new_value - delta
	if remaining_points < delta and delta > 0 and stat != "level":
		assert (new_value > old_value)
		delta = remaining_points
		new_value = old_value + delta
	
	var min_stat_value = get_min_stat_value(stat)
	assert (new_value >= min_stat_value)
	if new_value < min_stat_value:
		new_value = min_stat_value
		delta = new_value - old_value
	if stat == "level":
		character.level = new_value
	else:	
		character.set("boost_" + stat, new_value - character.get("base_" + stat))
	stat_hex.set_stats_for(character, null)
	sliders[stat].set_value(new_value)
	set_max_total(max_total)

func _unhandled_input(event):
	if not MenuHelper.is_in_top_menu(self):
		return 
	if event.is_action_pressed("ui_cancel"):
		cancel()
		get_tree().set_input_as_handled()

func cancel():
	if yield(MenuHelper.confirm("ARENAS_SKIP_STAT_ASSIGNMENT"), "completed"):
		.cancel()		

func _on_ConfirmButton_pressed():
	if remaining_points > 0:
		if not yield (MenuHelper.confirm("STAT_ADJUST_MENU_WARNING_POINTS_REMAIN"), "completed"):
			slider_container.grab_focus()
		else:
			var character_snapshot = character.get_snapshot()	
			choose_option(character_snapshot)				
	else:
		if yield (MenuHelper.confirm("ARENAS_STAT_ASSIGNMENT_COMPLETE"),"completed"):
			var character_snapshot = character.get_snapshot()	
			choose_option(character_snapshot)			

func choose_option(value):
	emit_signal("option_chosen", value)
