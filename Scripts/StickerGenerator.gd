static func configure_stickers(tape:MonsterTape):	
	var ExtraSlot = load("res://data/sticker_attributes/extra_slot.tres")
	
	tape.assign_initial_stickers(true)
	tape.upgrade_to(5, Random.new())	
	
	var maxslots = tape.form.move_slots
	var extra_slots:int = 0
	for upgrade in tape.form.tape_upgrades:
		if upgrade is TapeUpgradeMove:
			if upgrade.add_slot:
				maxslots += 1
				
	if tape.stickers.size() > maxslots:			
		var remove_count = tape.stickers.size() - maxslots
		for _i in range (remove_count):
			var sticker = tape.stickers[randi()%tape.stickers.size()]
			tape.stickers.erase(sticker)

	var duplicates:Dictionary = {}
	for sticker in tape.stickers:
		if duplicates.has(sticker.battle_move):			
			tape.stickers.erase(duplicates[sticker.battle_move])
		if not duplicates.has(sticker.battle_move):			
			duplicates[sticker.battle_move] = sticker	
	
	while tape.stickers.size() < maxslots:
		var new_sticker:Array = generate_stickers(Random.new(),tape.form.move_tags, 1, true)			
		if not duplicates.has(new_sticker[0].battle_move):
			tape.stickers.push_back(new_sticker[0])
			duplicates[new_sticker[0].battle_move] = new_sticker[0]
	var new_stickers:Array = []
	for sticker in tape.stickers:		
		if random_sticker_applied():		
			var new_sticker:Array  = generate_stickers(Random.new(),tape.form.move_tags, 1, true)						
			if not duplicates.has(new_sticker[0].battle_move):			
				duplicates.erase(sticker.battle_move)
				duplicates[new_sticker[0].battle_move] = new_sticker[0]
				sticker = new_sticker[0]
		if rare_sticker_applied() and move_is_upgradable(sticker.battle_move):
			sticker = upgrade_sticker(sticker)
			if rare_sticker_applied() and move_is_upgradable(sticker.battle_move):
				sticker = upgrade_sticker(sticker)
		new_stickers.push_back(sticker)

	for sticker in new_stickers:
		for attribute in sticker.attributes:			
			if attribute.get_script() == ExtraSlot.get_script():
				extra_slots += 1
	while extra_slots > 0:		
		var new_sticker:Array  = generate_stickers(Random.new(),tape.form.move_tags, 1, false)	
		if duplicates.has(new_sticker[0].battle_move):	
			continue
		for attribute in new_sticker[0].attributes:
			if attribute.get_script() == ExtraSlot.get_script():
				extra_slots += 1											
		new_stickers.push_back(new_sticker[0])
		duplicates[new_sticker[0].battle_move] = new_sticker[0]
		extra_slots -= 1
	
	var has_attack:bool = false
	for sticker in new_stickers:
		if sticker.battle_move.power > 0:
			has_attack = true
			break		

	while not has_attack:
		var new_sticker:Array = generate_stickers(Random.new(),tape.form.move_tags, 1, false)						
		if not duplicates.has(new_sticker[0].battle_move) and new_sticker[0].battle_move.power > 0:			
			new_stickers.remove(randi()%new_stickers.size())
			new_stickers.push_back(new_sticker[0])
			has_attack = true
			
		
	tape.stickers = new_stickers.duplicate()
static func move_is_upgradable(move:BattleMove)->bool:
	return move.attribute_profile != null
static func generate_stickers(rand:Random, sticker_tags, max_num:int = - 1, suppress_upgrade:bool = false)->Array:
	var stickers = []
	var moves:Array = []
	for tag in sticker_tags:
		moves += BattleMoves.get_moves_for_tag(tag)
	
	assert (moves.size() > 0)
	if moves.size() == 0:
		return []
	
	for _i in range(max_num):
		if moves.size() == 0:
			break
		var move = rand.choice(moves)
		moves.erase(move)
		var item = ItemFactory.generate_item(move, rand)
		assert (item != null)
		
		if rare_sticker_applied() and not suppress_upgrade and move_is_upgradable(move):
			item = ItemFactory.upgrade_rarity(item, rand)
			assert (item != null)
			assert (item.rarity >= BaseItem.Rarity.RARITY_UNCOMMON)
		
		stickers.push_back(item)
	
	return stickers	

static func random_sticker_applied()->bool:	
	var random_sticker_rate:float = 0.5
	return randf() < random_sticker_rate

static func rare_sticker_applied()->bool:
	var rare_sticker_rate:float = 0.3	
	return randf() < rare_sticker_rate

static func upgrade_sticker(sticker):
	return ItemFactory.upgrade_rarity(sticker, Random.new())
