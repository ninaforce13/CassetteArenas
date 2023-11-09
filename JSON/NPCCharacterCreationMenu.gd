extends "res://menus/BaseMenu.gd"

const ArrowOptionList = preload("res://nodes/menus/ArrowOptionList.gd")

const ARTIFICIAL_COLORS = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 21, 22, 23]
const DIRECTIONS = ["down", "right", "up", "left"]

const COLOR_VALUES = {
	"skin_color":ARTIFICIAL_COLORS, 
	"hair_color":ARTIFICIAL_COLORS, 
	"eye_color":ARTIFICIAL_COLORS, 
	"favorite_color":ARTIFICIAL_COLORS, 
	"body_color_1":ARTIFICIAL_COLORS, 
	"body_color_2":ARTIFICIAL_COLORS, 
	"face_accessory_color":ARTIFICIAL_COLORS, 
	"hair_accessory_color":ARTIFICIAL_COLORS, 
	"legs_color":ARTIFICIAL_COLORS, 
	"shoe_color":ARTIFICIAL_COLORS
}

const DLC_PARTS = {
	cosplay = {
		hair = ["bansheep", "candevil", "springheel", "traffikrab"], 
		body = ["pombomb"], 
		legs = ["pombomb"]
	}
}

export (Dictionary) var apperance_load:Dictionary = {}
export (Array, String) var hidden_options:Array = []
export (Array, String) var extra_hair_values:Array = []
export (Array, String) var extra_head_values:Array = []
export (Array, String) var extra_body_values:Array = []
export (Array, String) var extra_legs_values:Array = []
export (bool) var initial_randomize:bool = false
export (Color) var dlc_part_color:Color


onready var input_container = find_node("InputContainer")
onready var player_name_edit = find_node("Field_name")
onready var player_pronouns_edit = find_node("Field_pronouns")
onready var world_human_sprite = find_node("WorldHumanSprite")
onready var battle_human_sprite = find_node("BattleHumanSprite")
onready var buttons = find_node("Buttons")
onready var cancel_button = find_node("CancelButton")
onready var randomize_button = find_node("RandomizeButton")
onready var introdialog = find_node("IntroText")
onready var defeatdialog = find_node("DefeatText")
onready var biotext = find_node("BioText")

var character:Character = null
var t:float = 0.0
var char_config:CharacterConfig = null
var encounter_config:EncounterConfig = null
var tape_config:TapeConfig
var edit_mode:bool = false

func _ready():
	if character == null:
		character = Character.new()
	
	if character.name == "DEFAULT_PLAYER_NAME":
		character.name = tr(character.name)
	player_name_edit.text = character.name
	player_name_edit.max_width = Character.MAX_NAME_WIDTH
	player_pronouns_edit.set_selected_value(int(character.pronouns))
	
	var values = {
		hair = [], 
		head = [], 
		body = [], 
		legs = []
	}
	var sets = {
		hair = {}, 
		head = {}, 
		body = {}, 
		legs = {}
	}
	var font_color_overrides = {
		hair = {}, 
		head = {}, 
		body = {}, 
		legs = {}
	}
	var bodyparts = load("res://sprites/characters/world/human_layers/body.tres")
	var hairparts = load("res://sprites/characters/world/human_layers/hair.tres")
	var headparts = load("res://sprites/characters/world/human_layers/head.tres")
	var legparts = load("res://sprites/characters/world/human_layers/legs.tres")
	
	_append_unique(values.body, sets.body, bodyparts.part_names)
	_append_unique(values.hair, sets.hair, hairparts.part_names)
	_append_unique(values.legs, sets.legs, legparts.part_names)
	_append_unique(values.head, sets.head, headparts.part_names)
	
	_append_unique(values.hair, sets.hair, extra_hair_values)
	_append_unique(values.head, sets.head, extra_head_values)
	_append_unique(values.body, sets.body, extra_body_values)
	_append_unique(values.legs, sets.legs, extra_legs_values)
	
	for dlc_id in DLC_PARTS.keys():
		for key in DLC_PARTS[dlc_id].keys():
			_append_unique(values[key], sets[key], DLC_PARTS[dlc_id][key], font_color_overrides[key], true)
	
	for key in COLOR_VALUES.keys():
		setup_option_list_field(key, COLOR_VALUES[key], get_color_code(key), {})
		connect_color_list_field(key)
	var hair_values = character.human_part_names.get("hair")
	var head_values = character.human_part_names.get("head")
	var body_values = character.human_part_names.get("body")
	var legs_values = character.human_part_names.get("legs")
	if apperance_load:
		var loaded_values = JSON.parse(apperance_load.human_part_names).result
		hair_values = loaded_values.get("hair")
		head_values = loaded_values.get("head")
		body_values = loaded_values.get("body")
		legs_values = loaded_values.get("legs")
		set_initial_colors(JSON.parse(apperance_load.human_colors).result)
	setup_option_list_field("hair", values.hair, hair_values, font_color_overrides.hair)
	setup_option_list_field("head", values.head, head_values, font_color_overrides.head)
	setup_option_list_field("body", values.body, body_values, font_color_overrides.body)
	setup_option_list_field("legs", values.legs, legs_values, font_color_overrides.legs)
	connect_part_list_field("hair")
	connect_part_list_field("head")
	connect_part_list_field("body")
	connect_part_list_field("legs")
	
	for option in hidden_options:
		var node = find_node("Field_" + option)
		if node == null:
			continue
		_hide_option(node)
	input_container.setup_focus()
	
	world_human_sprite.idle = "run"
	
	if initial_randomize and not apperance_load:
		_on_RandomizeButton_pressed()
	if apperance_load:
		load_fighter()	
	
func _exit_tree():
	if AutoSplit.pause_for_character_creation:
		SaveState.timer_paused = false

func battle_part_substitution(input_part, input_key)->String:
	if input_part == "jacqueline" and input_key == "hair":
		return "long1"
	return input_part

func _append_unique(dest:Array, dict:Dictionary, src:Array, font_color_overrides = null, dlc = false):
	var exclusion_parts:Array = ["kayleigh","meredith","eugene","felix","viola","ianthe","gwen","coat1","dark"]
	for value in src:
		if value in exclusion_parts:
			continue
		if not dict.has(value):
			dict[value] = true
			dest.push_back(value)
			if font_color_overrides != null and dlc:
				font_color_overrides[value] = dlc_part_color

func get_color_code(key:String)->int:
	var color = character.human_colors.get(key, - 1)
	if color == - 1:
		return world_human_sprite.variable_ramps[key]
	return color

func setup_option_list_field(key:String, values:Array, initial_value, font_color_overrides:Dictionary):
	var node = find_node("Field_" + key)
	if node != null:
		node.values = values
		
		var labels = []
		for i in range(values.size()):
			var label_key = "UI_CC_VALUE_" + key + "_" + str(values[i])
			if Loc.key_exists(label_key):
				labels.push_back(tr(label_key))
			elif values[i] is String:
				var new_value:String = values[i]
				new_value = new_value.capitalize()
				labels.push_back(new_value)
			else:
				labels.push_back("%02d" % (i + 1))
				
		
		node.value_labels = labels
		node.value_font_color_overrides = font_color_overrides
		node.selected_value = initial_value
		
		node.adjust_min_size()

func connect_color_list_field(key:String):
	var field = find_node("Field_" + key)
	if field == null:
		return 
	field.connect("value_changed", self, "_on_color_changed", [key])
	_on_color_changed(field.selected_value, field.selected_index, key)

func connect_part_list_field(key:String):
	var field = find_node("Field_" + key)
	if field == null:
		return 
	field.connect("value_changed", self, "_on_part_changed", [key])
	_on_part_changed(field.selected_value, field.selected_index, key)

func _on_color_changed(value, _index:int, key:String):
	if not (value is int):
		return 
	world_human_sprite.colors[key] = value
	world_human_sprite.refresh()
	battle_human_sprite.colors[key] = value
	battle_human_sprite.refresh()

func set_initial_colors(human_colors:Dictionary):
	for key in human_colors.keys():
		var field = find_node("Field_" + key)
		field.selected_index = int(human_colors[key])
		_on_color_changed(int(human_colors[key]), 0, key) 
	pass

func _on_part_changed(value, _index:int, key:String):
	if not (value is String):
		return 
	world_human_sprite.part_names[key] = value
	if key == "body":
		world_human_sprite.part_names["arms"] = value
	world_human_sprite.refresh()
	value = battle_part_substitution(value, key)
	battle_human_sprite.part_names[key] = value
	if key == "body":
		battle_human_sprite.part_names["arms"] = value
	battle_human_sprite.refresh()

func _hide_option(cell:Control):
	assert (cell.get_parent() == input_container)
	if cell.get_parent() != input_container:
		return 
	
	var row = cell.get_index() / input_container.columns
	for _i in range(input_container.columns):
		var index = row * input_container.columns
		if index < input_container.get_child_count():
			var node = input_container.get_child(index)
			input_container.remove_child(node)
			node.queue_free()

func grab_focus():
	input_container.grab_focus()

func _process(delta):
	t += delta
	var rotations = int(t / 2.0) % 4
	world_human_sprite.direction = DIRECTIONS[rotations]

func _on_RandomizeButton_pressed():
	var parts = {}
	var colors = {}
	var template = HumanLayersHelper.randomize_sprite(null, parts, colors)
	find_node("Field_pronouns").set_selected_value(template.pronouns)
	
	for key in parts.keys():
		var node = find_node("Field_" + key)
		if node:
			node.set_selected_value(parts[key])
	for key in colors.keys():
		var node = find_node("Field_" + key)
		if node:
			node.set_selected_value(colors[key])

func _on_SaveButton_pressed():
	if not hidden_options.has("name"):
		if player_name_edit.text == "":
			character.name = tr("DEFAULT_PLAYER_NAME")
		else :
			character.name = player_name_edit.text
	if not hidden_options.has("pronouns"):
		character.pronouns = player_pronouns_edit.selected_value
	character.human_colors = world_human_sprite.colors.duplicate()
	character.human_part_names = world_human_sprite.part_names.duplicate()
	
	choose_option(get_dictionary())

func load_fighter():
	player_name_edit.text = apperance_load.name
	world_human_sprite.colors = JSON.parse(apperance_load.human_colors).result
	world_human_sprite.part_names = JSON.parse(apperance_load.human_part_names).result
	battle_human_sprite.part_names = world_human_sprite.part_names
	battle_human_sprite.colors = world_human_sprite.colors
	introdialog.text = apperance_load.introdialog
	defeatdialog.text = apperance_load.defeatdialog
	biotext.text = apperance_load.biotext
	battle_human_sprite.refresh()
	world_human_sprite.refresh()	

func get_dictionary()->Dictionary:
	if not hidden_options.has("name"):
		if player_name_edit.text == "":
			character.name = tr("DEFAULT_PLAYER_NAME")
		else :
			character.name = player_name_edit.text
	if not hidden_options.has("pronouns"):
		character.pronouns = player_pronouns_edit.selected_value
	character.human_colors = world_human_sprite.colors.duplicate()
	character.human_part_names = world_human_sprite.part_names.duplicate()
	var my_dict:Dictionary = {"name":character.name, 
							"human_part_names":to_json(character.human_part_names), 
							"human_colors":to_json(character.human_colors),
							"pronouns":character.pronouns,
							"introdialog":introdialog.text,
							"defeatdialog":defeatdialog.text,
							"biotext":biotext.text,
							"recruiter":SaveState.party.player.name if not edit_mode else apperance_load.recruiter,
							"recruiter_id":SaveState.get_ranger_id() if not edit_mode else apperance_load.recruiter_id}
	return my_dict 		

func _on_Field_name_focus_entered():
	randomize_button.disabled = true

func _on_Field_name_focus_exited():
	randomize_button.disabled = false

func _on_CancelButton_pressed():
	choose_option(null)
