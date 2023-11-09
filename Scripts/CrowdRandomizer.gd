extends Node

export(float) var jump_chance = 0.4
export(float) var flight_chance = 0.4 
var humannpc_script = preload("res://world/npc/HumanNPC.gd")

func _enter_tree():
	if not HumanLayersHelper.human_templates:
		HumanLayersHelper.setup()	
	for child in get_children():
		if child.get_script() == humannpc_script:
			child.randomize_sprite()
			var control = child.get_node("Controls")
			control.jump = false
			control.force_fly = false
			if randf() < jump_chance:
				jump(control)
			if randf() < flight_chance:
				control.force_fly = true

func jump(control):
	yield(Co.wait(rand_range(0.5, 4.0)), "completed")
	control.jump = true	
