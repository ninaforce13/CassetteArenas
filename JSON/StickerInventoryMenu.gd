extends "res://menus/BaseMenu.gd"

export (Array) var monster_stickers = []
export (bool) var immediate_item_use:bool = true setget set_immediate_item_use
export (Array, String) var tab_filter:Array = []

onready var detail_panel = find_node("DetailPanel")
onready var inventory_list = find_node("StickerButtons")
onready var cog_tween = $CogTween
onready var cog = $Scroller / Cog
onready var cog_shadow = $Scroller / CogShadow
onready var mouse_blocker = $MouseBlocker
onready var sort_button = find_node("SortButton")
onready var back_button = find_node("BackButton")

var inventory = null
var context = null setget set_context
var items_in_use = []
var sticker_index:int = 0
const itemnode = preload("res://mods/RangerArena/UI/itemnode.tscn")
var invert:bool = false

func _ready():
	set_immediate_item_use(immediate_item_use)
	set_context(context)
	set_inventory(monster_stickers)
	_on_SortButton_pressed()
	
func grab_focus():
	if inventory_list.get_child_count() > 0:				
		inventory_list.get_child(sticker_index).grab_focus()

func get_button_index(item):
	var index:int = 0
	for button in inventory_list.get_children():
		if item == button:
			return index
		index += 1
	return 0
func set_context(value):
	context = value
	if detail_panel:
		detail_panel.context = value
		$BackButtonPanel.back_text_override = "UI_BUTTON_CANCEL" if context != null else ""

func set_immediate_item_use(value:bool):
	immediate_item_use = value
	if detail_panel:
		detail_panel.immediate_item_use = immediate_item_use

func set_inventory(stickers:Array):		
	for sticker in stickers:
		var item = itemnode.instance()
		item.get_child(0).set_item(sticker)
		item.get_child(0).set_amount(1)
		item.text = item.get_child(0).get_item_name()
		item.icon = item.get_child(0).get_icon()
		inventory_list.add_child(item)
		item.connect("focus_entered", self, "_on_item_focused",[item.get_child(0), item])
		item.connect("pressed", self, "_on_item_selected",[item.get_child(0)])
	inventory_list.setup_focus()
	
func rotate_cog(num_stops:int):
	cog_tween.stop_all()
	cog_tween.remove_all()
	cog_tween.interpolate_property(cog, "rect_rotation", cog.rect_rotation, cog.rect_rotation + num_stops * 45.0, 0.25, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	cog_tween.interpolate_property(cog_shadow, "rect_rotation", cog.rect_rotation, cog.rect_rotation + num_stops * 45.0, 0.25, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	cog_tween.start()

func _on_item_focused(item, button):
	sticker_index = get_button_index(button)
	detail_panel.set_item_node(item)

func flip_button_detection():
	back_button.detect_action = not back_button.detect_action
	sort_button.detect_action = not sort_button.detect_action
	
func _on_item_selected(item):
	flip_button_detection()
	detail_panel.set_item_node(item)
	detail_panel.grab_focus()

func _on_item_used(item, arg):
	choose_option({
			"item":item, 
			"arg":arg
		})
		
func _on_DetailPanel_canceled():
	flip_button_detection()
	grab_focus()

func _on_DetailPanel_block_mouse():
	print("blocked mouse")
	mouse_blocker.visible = true
	Controls.set_disabled($BackButtonPanel, true)

func _on_DetailPanel_unblock_mouse():
	print("unblocked mouse")
	mouse_blocker.visible = false
	Controls.set_disabled($BackButtonPanel, false)

func _cmp_item_node(a, b)->bool:
	if a.get_child(0).item.get_sort_order() < b.get_child(0).item.get_sort_order():
		return true
	if a.get_child(0).item.get_sort_order() > b.get_child(0).item.get_sort_order():
		return false
	
	var aname = Strings.strip_bbcode(tr(a.get_child(0).get_sortable_name()))
	var bname = Strings.strip_bbcode(tr(b.get_child(0).get_sortable_name()))
	var name_cmp = aname.naturalnocasecmp_to(bname)
	if name_cmp < 0:
		return true
	if name_cmp > 0:
		return false
	
	if a.get_child(0).item.get_rarity() > b.get_child(0).item.get_rarity():
		return true
	if a.get_child(0).item.get_rarity() < b.get_child(0).item.get_rarity():
		return false
	
	return false



func _on_SortButton_pressed():
	var sorted = inventory_list.get_children()
	sorted.sort_custom(self,"_cmp_item_node")
	if invert:
		sorted.invert()
	var index:int = 0
	for item in sorted:
		inventory_list.move_child(item,index)
		index += 1
	inventory_list.setup_focus()
	invert = not invert
