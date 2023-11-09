extends Control

signal option_chosen(option)

onready var buttons = $Buttons
onready var edit_trainee_btn = $Buttons / EditTrainee
onready var select_trainee_btn = $Buttons / SelectPartner
onready var cancel_btn = $Buttons / CancelBtn
var partner_select:bool = false

func _ready():					
	if partner_select:
		buttons.remove_child(edit_trainee_btn)
		edit_trainee_btn.queue_free()
	else:
		buttons.remove_child(select_trainee_btn)
		select_trainee_btn.queue_free()
						
	buttons.setup_focus()

func _process(_delta):
	if not get_focus_owner() or not is_a_parent_of(get_focus_owner()):
		choose_option(null)

func choose_option(option):
	emit_signal("option_chosen", option)
	get_parent().remove_child(self)
	queue_free()

func _on_CancelBtn_pressed():
	choose_option(null)

func _unhandled_input(event):
	if not MenuHelper.is_in_top_menu(self):
		return 
	if get_focus_owner() != null and is_a_parent_of(get_focus_owner()):
		if event.is_action_pressed("ui_cancel"):
			get_tree().set_input_as_handled()
			_on_CancelBtn_pressed()


func grab_focus():
	buttons.grab_focus()

func _on_TapeActionButtons_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		choose_option(null)

func _on_EditTrainee_pressed():
	choose_option("edit_trainee")


func _on_SelectPartner_pressed():
	choose_option("select_partner")
