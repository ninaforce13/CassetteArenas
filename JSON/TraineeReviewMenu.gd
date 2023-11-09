extends "res://menus/BaseMenu.gd"

signal show_edit_buttons
const trainee_btn = preload("res://mods/RangerArena/UI/TraineeBtn.tscn")
const traine_edit_btns = preload("res://mods/RangerArena/JSON/ReEditActionButtons.tscn")
const ranger_recruiter_menu = preload("res://mods/RangerArena/JSON/RangerRecruiter.tscn")
onready var emptylabel = find_node("EmptyLabel")
onready var world_human_sprite = find_node("WorldHumanSprite")
onready var battle_human_sprite = find_node("BattleHumanSprite")
onready var player_name_edit = find_node("PlayerName")
onready var content_container = find_node("ContentContainer")
onready var introtext = find_node("IntroDialogText")
onready var defeattext = find_node("DefeatDialogText")
onready var biotext = find_node("BiographyText")
onready var recruiter = find_node("RecruiterName")
onready var recruiter_id = find_node("RecruiterID")
onready var assigned_tapes = find_node("Tapes")
onready var trainee_buttons = find_node("TraineeButtons")
onready var stat_hex = find_node("StatHex")
onready var empty_label = find_node("EmptyLabel")
onready var action_buttons_parent = find_node("ActionButtonsParent")
onready var action_icon_buttons = [ 
	find_node("ExitButton")
]

const DIRECTIONS = ["down", "right", "up", "left"]
const trainee_base_stats = preload("res://mods/RangerArena/Characters/trainee.tres")
var time:float = 0.0
var rangerdata = preload("res://mods/RangerArena/JSON/RangerDataParser.gd")
var current_recruit
var current_index:int

func _ready():
	parse_ranger_data()
	
func parse_ranger_data():
	var datapath = rangerdata.get_directory()
	var files:Array = rangerdata.get_files(datapath)
	var recruits:Array = rangerdata.read_json(files)	
	if recruits.size() > 0:		
		add_trainee_buttons(recruits)
	empty_label.visible = recruits.size() == 0
		
	
func add_trainee_buttons(recruits:Array):
	var first_button
	var index:int = 0
	for recruit in recruits:
		var trainee_btn_instance = trainee_btn.instance()
		trainee_btn_instance.text = recruit.name
		var sprite = trainee_btn_instance.get_node("ViewportContainer/Viewport/WorldHumanSprite")
		var texture = trainee_btn_instance.get_node("MonsterSticker")
		texture.texture = get_signature_sticker(recruit)
		sprite.colors = JSON.parse(recruit.human_colors).result
		sprite.part_names = JSON.parse(recruit.human_part_names).result				
		trainee_buttons.add_child(trainee_btn_instance)
		sprite.refresh()
		trainee_btn_instance.connect("focus_entered", self, "_on_trainee_focus",[index, recruit])
		trainee_btn_instance.connect("pressed", self, "_on_trainee_pressed", [index,recruit])
		if index == 0:
			first_button = trainee_btn_instance
		index += 1
			
	emptylabel.visible = trainee_buttons.get_child_count() == 0
	if first_button:
		trainee_buttons.initial_focus = trainee_buttons.get_path_to(first_button)
	else :
		trainee_buttons.initial_focus = NodePath()
	
	trainee_buttons.setup_focus()
	trainee_buttons.get_child(0).grab_focus()
	
func _on_trainee_focus(button, recruit):
	load_fighter(recruit)
	load_tapes(recruit)
	load_stats(recruit)

func grab_focus():
	if trainee_buttons.get_child_count() > 0:
		trainee_buttons.get_child(0).grab_focus()
	
func _process(delta):
	time += delta
	var rotations = int(time / 2.0) % 4
	world_human_sprite.direction = DIRECTIONS[rotations]

func load_fighter(result):
	player_name_edit.text = result.name
	world_human_sprite.colors = JSON.parse(result.human_colors).result
	world_human_sprite.part_names = JSON.parse(result.human_part_names).result
	battle_human_sprite.part_names = JSON.parse(result.human_part_names).result
	battle_human_sprite.colors = JSON.parse(result.human_colors).result
	introtext.text = result.introdialog
	defeattext.text = result.defeatdialog
	biotext.text = result.biotext
	recruiter.text = result.recruiter
	recruiter_id.text = result.recruiter_id
	battle_human_sprite.refresh()
	world_human_sprite.refresh()	
	
func load_tapes(result:Dictionary):
	var index:int = 0
	for child in assigned_tapes.get_children():
		var key = "tape"+str(index)
		var tape = MonsterTape.new()
		if result.has(key):
			result[key] = rangerdata.get_custom_monster(result[key])
			tape.set_snapshot(result[key], 1)
			if tape and tape.form:
				child.get_child(0).tape = tape
			else:
				child.get_child(0).tape = null
		if not result.has(key):
			child.get_child(0).tape = null
		index +=1

func get_signature_sticker(result:Dictionary)->Texture:
	var index:int = 0
	var texture:Texture
	for key in result.keys():
		if key == "tape"+str(index):
			if result[key].favorite:				
				var tape = MonsterTape.new()
				result[key] = rangerdata.get_custom_monster(result[key])
				tape.set_snapshot(result[key], 1)
				if tape and tape.form:
					return tape.form.tape_sticker_texture
			index +=1	
	return texture
	
func load_stats(result:Dictionary):
	var character = Character.new()	
	if result.has("stats"):
		character.set_snapshot(result["stats"],1)
	if not result.has("stats"):
		character.set_snapshot(trainee_base_stats.get_snapshot(),1)
	character.level = 100		
	stat_hex.set_stats_for(character, null, null)	
	
func choose_option(value):
	emit_signal("option_chosen", value)
	
func _on_ExitButton_pressed():
	cancel()

func _on_trainee_pressed(index:int, recruit:Dictionary):	
	emit_signal("show_edit_buttons")
	current_recruit = recruit
	current_index = index
	action_icon_buttons[0].detect_action = false

	var buttons = traine_edit_btns.instance()
	action_buttons_parent.add_child(buttons)
	buttons.connect("option_chosen", self, "_on_ActionButtons_option_chosen")
	buttons.grab_focus()		
	trainee_buttons.get_child(current_index).set("custom_colors/font_color",Color.white)
	  
func _on_ActionButtons_option_chosen(option):
	var co = null
	action_icon_buttons[0].detect_action = true
	if option == "edit_trainee":
		co = _on_edit_trainee_option_chosen(current_recruit)
	if co is GDScriptFunctionState:
		yield (co, "completed")
	trainee_buttons.get_child(current_index).set("custom_colors/font_color",Color(0.576471, 0.32549, 0.32549))
	trainee_buttons.get_child(current_index).grab_focus()
	
func _on_edit_trainee_option_chosen(recruit:Dictionary):
	var result = yield(show_recruiter_menu(recruit), "completed")
	if result:
		var trainee_btn = trainee_buttons.get_child(current_index)	
		trainee_btn.disconnect("pressed", self, "_on_trainee_pressed")	
		trainee_btn.disconnect("focus_entered", self, "_on_trainee_focus")	
		trainee_btn.text = result.name
		var sprite = trainee_btn.get_node("ViewportContainer/Viewport/WorldHumanSprite")
		var texture = trainee_btn.get_node("MonsterSticker")
		texture.texture = get_signature_sticker(result)
		sprite.colors = JSON.parse(result.human_colors).result
		sprite.part_names = JSON.parse(result.human_part_names).result				
		sprite.refresh()
		recruit = result
		trainee_btn.connect("pressed", self, "_on_trainee_pressed",[current_index,recruit])	
		trainee_btn.connect("focus_entered", self, "_on_trainee_focus",[current_index,recruit])			

		
func show_recruiter_menu(recruit:Dictionary):	
	var menu = ranger_recruiter_menu.instance()
	menu.loaded_recruit = recruit
	MenuHelper.add_child(menu)
	var result = yield (menu.run_menu(), "completed")
	menu.queue_free()	
	return result
