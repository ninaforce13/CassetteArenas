extends SpawnConfig
class_name RangerSpawnConfig

const BlankMonster = preload("res://data/characters/blank_monster.tres")

export (Array, Resource) var monster_forms:Array = []
export (PackedScene) var world_ranger:PackedScene
export (Character.CharacterKind) var character_kind:int = Character.CharacterKind.HUMAN
export (bool) var disable_fleeing:bool = false
export (String, "", "monster", "monster_dlc") var level_scale_override_key:String = ""

func spawn()->Node:
	assert (world_ranger != null)
	var node = world_ranger.instance()
	return _configure_ranger(node)

func spawn_async()->Node:
	assert (world_ranger != null)
	var node = yield (InstanceQueue.instance_async(world_ranger), "completed")
	return _configure_ranger(node)

func _configure_ranger(node:Node)->Node:
	var encounter = EncounterConfig.new()
	encounter.name = "EncounterConfig"
	node.add_child(encounter)
	
	var first = true
	
	for mon in monster_forms:
		var c = CharacterConfig.new()
		c.base_character = BlankMonster
		c.pronouns = randi() % 3
		c.character_kind = character_kind
		
#		c.level_boost = LEVEL_BOOST
#		c.level_boost_frac = LEVEL_BOOST_FRAC
#		c.level_boost_randomness = LEVEL_BOOST_RANDOMNESS
#		c.night_level_boost_frac = NIGHT_LEVEL_BOOST_FRAC
		
		encounter.add_child(c)
		encounter.move_child(c, randi() % encounter.get_child_count())
		var tape = TapeConfig.new()
		tape.form = mon

		c.add_child(tape)		
	
	encounter.can_flee = not disable_fleeing
	
	return node
