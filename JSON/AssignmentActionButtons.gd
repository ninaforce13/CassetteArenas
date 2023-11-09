extends Control

signal option_chosen(option)

onready var buttons = $Buttons
onready var edit_trainee_btn = $Buttons / EditTrainee
onready var edit_stickers_btn = $Buttons / EditStickersBtn
onready var bootleg_btn = $Buttons / SetBootlegTypeBtn
onready var put_away_btn = $Buttons / PutAwayBtn
onready var add_to_party_btn = $Buttons / AddToPartyBtn
onready var cancel_btn = $Buttons / CancelBtn
onready var signature_btn = $Buttons / SignatureBtn

var is_party:bool = false
var tape:MonsterTape

func _ready():					
	if is_party:
		buttons.remove_child(add_to_party_btn)
		add_to_party_btn.queue_free()
		add_to_party_btn = null
	else:
		if edit_stickers_btn:
			buttons.remove_child(edit_stickers_btn)
			edit_stickers_btn.queue_free()
		if put_away_btn:
			buttons.remove_child(put_away_btn)
			put_away_btn.queue_free()
		if signature_btn:
			buttons.remove_child(signature_btn)
			signature_btn.queue_free()
		if bootleg_btn:
			buttons.remove_child(bootleg_btn)
			bootleg_btn.queue_free()
					
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

func _on_CheckTapeBtn_pressed():
	choose_option("check_tape")

func _on_AddToPartyBtn_pressed():
	choose_option("add_to_party")

func grab_focus():
	buttons.grab_focus()

func _on_TapeActionButtons_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		choose_option(null)

func _on_PutAwayBtn_pressed():
	choose_option("put_away")

func _on_SignatureBtn_pressed():
	choose_option("set_signature")

func _on_EditStickers_pressed():
	choose_option("edit_stickers")

func _on_SetBootlegTypeBtn_pressed():
	choose_option("set_bootleg")


func _on_EditTrainee_pressed():
	choose_option("edit_trainee")
