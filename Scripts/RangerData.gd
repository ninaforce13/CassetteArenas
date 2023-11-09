extends Resource
class_name RangerData

export	(String) var name = ""
export (Dictionary) var human_colors:Dictionary 
export (Dictionary) var human_part_names:Dictionary 
export (int, "He", "She", "They") var pronouns:int = 2 
export (String) var introdialog = "Let's go!"
export (String) var defeatdialog = "Fine, you win!"
export (String) var biotext = "a ranger."
export (String) var recruiter = "Bytten Studio"
export (String) var recruiter_id = "0000-0000"
export (Resource) var tape0 
export (Resource) var tape1 
export (Resource) var tape2 
export (Resource) var tape3 
export (Resource) var tape4 
export (Resource) var tape5 
export (Dictionary) var stats = null
export (float) var version = 1.1
export (bool) var default_stickers = true



func get_snapshot():
	if default_stickers:
		tape0.assign_initial_stickers(false,null,true)
		tape1.assign_initial_stickers(false,null,true)
		tape2.assign_initial_stickers(false,null,true)
		tape3.assign_initial_stickers(false,null,true)
		tape4.assign_initial_stickers(false,null,true)
		tape5.assign_initial_stickers(false,null,true)
	
	if stats == null:
		var character = load("res://mods/RangerArena/Characters/trainee.tres")
		stats = character.get_snapshot()
	var snap:Dictionary = {
		"name":name,
		"human_colors":human_colors,
		"human_part_names":human_part_names,
		"pronouns":pronouns,
		"introdialog":introdialog,
		"defeatdialog":defeatdialog,
		"biotext":biotext,
		"recruiter":recruiter,
		"recruiter_id":recruiter_id,
		"tape0":tape0.get_snapshot(),
		"tape1":tape1.get_snapshot(),
		"tape2":tape2.get_snapshot(),
		"tape3":tape3.get_snapshot(),
		"tape4":tape4.get_snapshot(),
		"tape5":tape5.get_snapshot(),
		"stats":stats,
		"version":version
							}
	return snap
	
