extends "res://menus/inventory/ItemInfoPanel.gd"

signal block_mouse
signal unblock_mouse
signal item_used(item_node, arg)
signal exiting_recycle_mode
signal canceled


onready var buttons = find_node("Buttons")

var item_node:Node setget set_item_node
var context = null setget set_context
var context_kind:int
var immediate_item_use:bool = true

func set_item_node(value):
	item_node = value
	item = item_node.item if item_node else null
	amount = item_node.amount if item_node else 0
	refresh()

func set_context(value):
	context = value
	if context is MonsterTape:
		context_kind = BaseItem.ContextKind.CONTEXT_TAPE
	elif context is Character:
		context_kind = BaseItem.ContextKind.CONTEXT_CHARACTER
	elif context is FighterNode:
		context_kind = BaseItem.ContextKind.CONTEXT_BATTLE
	elif context == null:
		context_kind = BaseItem.ContextKind.CONTEXT_WORLD
	refresh()

func refresh():
	.refresh()
	var had_focus = get_focus_owner() != null and is_a_parent_of(get_focus_owner())
	for button in buttons.get_children():
		buttons.remove_child(button)
		button.queue_free()
	if had_focus:
		grab_focus()

func should_have_focus():
	return buttons.get_child_count() > 0

func grab_focus():
	for button in buttons.get_children():
		buttons.remove_child(button)
		button.queue_free()
	
	if item_node != null and item_node.is_usable(context_kind, context):
		for option in item_node.get_use_options(context_kind, context):
			var button = Button.new()
			button.text = option.label
			button.disabled = option.get("disabled", false)
			button.connect("pressed", self, "_on_use_button_pressed", [button, option.arg])
			buttons.add_child(button)
	else :
		var button = Button.new()
		button.text = "ITEM_USE"
		button.set_disabled(true)
		buttons.add_child(button)	
	
	var cancel_button = Button.new()
	cancel_button.text = "UI_BUTTON_CANCEL"
	cancel_button.connect("pressed", self, "_on_cancel_button_pressed")
	buttons.add_child(cancel_button)
	
	buttons.visible = true
	buttons.setup_focus()
	buttons.get_child(0).grab_focus()

func _on_use_button_pressed(button, arg):
	emit_signal("block_mouse")
	button.release_focus()
	buttons.visible = false
	
	yield (Co.next_frame(), "completed")
	yield (Co.next_frame(), "completed")	
	arg = item_node.custom_use_menu(context_kind, context, arg)
	if arg is GDScriptFunctionState:
		arg = yield (arg, "completed")
		if arg == null:
			
			buttons.visible = true
			button.grab_focus()
			emit_signal("unblock_mouse")
			return 
	if immediate_item_use:
		var co = item_node.use(context_kind, context, arg)
		if co is GDScriptFunctionState:
			yield (co, "completed")
	buttons.visible = true

	emit_signal("unblock_mouse")
	emit_signal("item_used", item_node, arg)

func _on_cancel_button_pressed():
	emit_signal("canceled")

func _unhandled_input(event):
	if not MenuHelper.is_in_top_menu(self):
		return 
	if get_focus_owner() != null and is_a_parent_of(get_focus_owner()):
		if event.is_action_pressed("ui_cancel"):
			_on_cancel_button_pressed()
			get_tree().set_input_as_handled()
