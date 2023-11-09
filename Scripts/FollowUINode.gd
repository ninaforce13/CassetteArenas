extends Node

export (NodePath) var follow_path
export (float) var x_offset = 0.0
export (float) var y_offset = 0.0
var follow_node:Node

func _ready():
	follow_node = get_node(follow_path)
	set_process(false)

func update_position():
	self.rect_position = follow_node.rect_position
	self.rect_position.y += y_offset
	self.rect_position.x += x_offset
