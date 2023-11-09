extends "res://menus/BaseMenu.gd"

export (NodePath) var animator
export (Resource) var player1
export (Resource) var player2
export (Resource) var player3
export (Resource) var player4
var animation_node

func _ready():

	var sprite_container1 = get_node("%MonsterSpriteContainer1")
	var sprite_container2 = get_node("%MonsterSpriteContainer2")
	var sprite_container3 = get_node("%MonsterSpriteContainer3")
	var sprite_container4 = get_node("%MonsterSpriteContainer4")
	var player_name1 = get_node("%PlayerName1")
	var player_name2 = get_node("%PlayerName2")
	var player_name3 = get_node("%PlayerName3")
	var player_name4 = get_node("%PlayerName4")
	
	if player1.battle_sprite:
		sprite_container1.sprite = player1.battle_sprite
		
	else: 
		sprite_container1.sprite = player1.battle_sprite_instance()
	player_name1.text = player1.name
	if player2.battle_sprite:
		sprite_container2.sprite = player2.battle_sprite
	else: 
		sprite_container2.sprite = player2.battle_sprite_instance()
	player_name2.text = player2.name
	if player3.battle_sprite:
		sprite_container3.sprite = player3.battle_sprite
	else: 
		sprite_container3.sprite = player3.battle_sprite_instance()	
	player_name3.text = player3.name
	if player4.battle_sprite:
		sprite_container4.sprite = player4.battle_sprite
	else: 
		sprite_container4.sprite = player4.battle_sprite_instance()	
	player_name4.text = player4.name
func play_hide_animation():
	animation_player.play("Hide")
	yield (animation_player, "animation_finished")
