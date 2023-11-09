extends Control

var ElementalTypes = Datatables.load("res://data/elemental_types")

onready var background = $ViewportContainer / Viewport / Background
var monster_forms:Array = []
var slot

func _ready():
	GlobalUI.manage_visibility($VBoxContainer)
	
	monster_forms = Datatables.load("res://data/monster_forms/").table.values()	
	

func update_slots(selected_form):
	var slots = background.get_slots()
	slot = background.get_slots()[0]
	for j in range(1, slots.size()):
		slots[j].clear()
	
	slot.translation.x = 0.0
	
	update_selection(selected_form)

func update_selection(selected_form):
	var form = selected_form
	
	var palette = []
	var sparkle = false
	
	sparkle = sparkle or slot.form.get_sparkle()
	
	slot.set_palette(palette)
	slot.set_sparkle(sparkle)
	
	slot.sprite_container.idle = "idle"
	slot.sprite_container.alt_idle = "idle"

func _on_item_selected(_id):
	update_selection(_id)

