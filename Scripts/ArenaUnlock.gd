extends SlidingControl

const CORNERS = {
	dash = preload("res://menus/new_ability/corner_dash_1.png"), 
	flight = preload("res://menus/new_ability/corner_flight_1.png"), 
	glide = preload("res://menus/new_ability/corner_glide_1.png"), 
	magnetism = preload("res://menus/new_ability/corner_magnetism_1.png"), 
	swim = preload("res://menus/new_ability/corner_swim_1.png"), 
	climb = preload("res://menus/new_ability/corner_vine_1.png")
}

export (String) var ability:String = "glide" 
export (String) var description:String = " The Cassette Arena is now open to the public. Speak to the Arena Attendant in the Town Hall to participate."
export (String) var corner_decor = "dash"
onready var ability_name_label = find_node("AbilityNameLabel")
onready var description_label = find_node("DescriptionLabel")
onready var audio_stream_player = $AudioStreamPlayer
onready var corner_container = $NoTransform / CornerContainer

func _ready():
	set_ability(ability)
	
	if SceneManager.current_scene == self:
		run_menu()
	
	InputIcons.connect("icons_changed", self, "update_description")

func update_description():
	var font_height = description_label.get_font("normal_font").get_height()
	description_label.bbcode_text = "[center]" + ability + description + "[/center]"

func set_ability(value:String):
	ability = value
	if corner_container:
		for node in corner_container.get_children():
			for child in node.get_children():
				node.remove_child(child)
				child.queue_free()
		
		update_description()
		
		ability_name_label.text = ability
		
		var corner = CORNERS.get(corner_decor)
		if not corner:
			return 

		

func run_menu():
	hidden_offset = Vector2(2, 0)
	scaled_offset = hidden_offset
	yield (show(), "completed")
	hidden_offset = Vector2( - 2, 0)
	yield (self, "hidden")

func _play_audio():
	MusicSystem.mute = true
	audio_stream_player.play()
	yield (Co.safe_wait_for_audio(self, audio_stream_player), "completed")
	MusicSystem.mute = false

func _exit_tree():
	MusicSystem.mute = false

func show():
	_play_audio()
	corner_container.visible = false
	yield (.show(), "completed")
	
	corner_container.visible = true
	for child in corner_container.get_children():
		if not child.has_node(NodePath("Sprite/AnimationPlayer")):
			continue
		var anim = child.get_node(NodePath("Sprite/AnimationPlayer")) as AnimationPlayer
		anim.play("animation_1")

func hide(keep_visible:bool = false):
	corner_container.visible = true
	for child in corner_container.get_children():
		if not child.has_node(NodePath("Sprite/AnimationPlayer")):
			continue
		var anim = child.get_node(NodePath("Sprite/AnimationPlayer")) as AnimationPlayer
		anim.play_backwards("animation_1")
	
	return .hide(keep_visible)

func _unhandled_input(event:InputEvent):
	if not visible or tween.is_active() or not MenuHelper.is_in_top_menu(self):
		return 
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		cancel()
		get_tree().set_input_as_handled()

func _on_CloseButton_pressed():
	if cancelable and visible and not tween.is_active():
		cancel()

