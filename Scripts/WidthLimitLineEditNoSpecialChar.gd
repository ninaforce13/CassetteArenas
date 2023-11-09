extends LineEdit

const WIDTH_MEASURE_FONTS = [
	preload("res://ui/fonts/regular/regular_36.en.tres"), 
	preload("res://ui/fonts/regular/regular_36.jp.tres"), 
	preload("res://ui/fonts/regular/regular_36.kr.tres"), 
	preload("res://ui/fonts/regular/regular_36.sc.tres")
]

export (int) var max_width:int
export (bool) var convert_to_upper:bool = false
var allowed_characters = "[A-Z a-z0-9#]"
func _ready():
	connect("text_changed", self, "_on_text_changed")

func _max_text_width(text:String):
	var result = 0
	for font in WIDTH_MEASURE_FONTS:
		var w = font.get_string_size(text).x
		result = max(result, w)
	return result

func _on_text_changed(new_text:String):
	validate_input(new_text)
	
	var pos = caret_position
	if convert_to_upper:
		new_text = new_text.to_upper()
		text = new_text
		caret_position = pos
	if max_width == 0:
		return 
	var width = _max_text_width(new_text)
	if max_length == 0:
		max_length = new_text.length()
	while width > max_width:
		max_length -= 1
		width = _max_text_width(new_text.substr(0, max_length))
	if width == max_width:
		max_length = new_text.length()
	else :
		max_length = 0
	caret_position = pos

func validate_input(new_text):
	var old_caret_position = self.caret_position

	var word = ''
	var regex = RegEx.new()
	regex.compile(allowed_characters)
	for valid_character in regex.search_all(new_text):
		word += valid_character.get_string()
	self.set_text(word)

	caret_position = old_caret_position		
