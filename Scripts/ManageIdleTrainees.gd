extends Node

var trainee_list:Array = []
var rangerdata = preload("res://mods/RangerArena/JSON/RangerDataParser.gd")

func _init():
	var files = rangerdata.get_files(rangerdata.get_directory())
	trainee_list = rangerdata.read_json(files)

func get_a_trainee():
	if trainee_list.size() > 0:
		var random_index = randi()%trainee_list.size()
		var chosen_trainee = trainee_list[random_index].duplicate()
		trainee_list.remove(random_index)	
		return chosen_trainee

