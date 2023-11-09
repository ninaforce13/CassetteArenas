extends Node

export (String, "up", "down", "left", "right") var crowd_face_direction
export (float) var jump_chance = 0.5
export (Vector3) var scale_override = Vector3.ONE
export (Array, PackedScene) var monster_forms

func _ready():
	for spawn_position in self.get_children():
		var npc_instance = monster_forms[randi() % monster_forms.size()].instance()
		add_child(npc_instance)
		npc_instance.initial_direction = crowd_face_direction
		npc_instance.transform = spawn_position.transform
		npc_instance.scale = scale_override
		if randf() < jump_chance:
			npc_instance.get_node("Controls").jump = true
