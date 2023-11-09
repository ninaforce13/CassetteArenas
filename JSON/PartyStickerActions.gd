extends "res://nodes/menus/AutoFocusConnector.gd"

signal option_chosen(option, value)

onready var apply_sticker_btn = $ApplyStickerBtn
onready var peel_sticker_btn = $PeelStickerBtn
onready var move_sticker_btn = $MoveStickerBtn
onready var apply_uncommon_btn = $ApplyUncommonEffectBtn
onready var apply_rare_btn = $ApplyRareEffectBtn
onready var remove_effect_btn = $RemoveEffectBtn
onready var cancel_btn = $CancelBtn

var applying_sticker:StickerItem = null
var tape:MonsterTape
var sticker_index:int
var uncommon_full:bool = false
var rare_full:bool = false
var no_effects:bool = false

func _ready():
	assert (tape != null)
	var sticker = get_sticker()
	assert (sticker == null or sticker is BattleMove or sticker is StickerItem)
	
	if sticker == null or applying_sticker != null:
		remove_child(peel_sticker_btn)
		peel_sticker_btn.queue_free()
		remove_child(move_sticker_btn)
		move_sticker_btn.queue_free()
	
	if uncommon_full or sticker == null:
		remove_child(apply_uncommon_btn)
		apply_uncommon_btn.queue_free()
	if rare_full or sticker == null:
		remove_child(apply_rare_btn)
		apply_rare_btn.queue_free()
	if no_effects or sticker == null:
		remove_child(remove_effect_btn)
		remove_effect_btn.queue_free()
	
	if sticker != null:
		apply_sticker_btn.text = "UI_PARTY_REPLACE_STICKER"
		if not tape.sticker_can_be_replaced(sticker_index):
			apply_sticker_btn.disabled = true
	
	setup_focus()

func get_sticker()->Resource:
	if sticker_index < tape.stickers.size():
		return tape.stickers[sticker_index]
	return null

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
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		_on_CancelBtn_pressed()

func _on_ApplyStickerBtn_pressed():
	choose_option("apply_sticker")

func _on_PeelStickerBtn_pressed():
	choose_option("peel_sticker")

func _on_MoveStickerBtn_pressed():
	choose_option("move_sticker")

func _on_ApplyUncommonEffectBtn_pressed():		
	choose_option("apply_uncommon")

func _on_ApplyRareEffectBtn_pressed():	
	choose_option("apply_rare")

func _on_RemoveEffectBtn_pressed():
	choose_option("remove_effect")
