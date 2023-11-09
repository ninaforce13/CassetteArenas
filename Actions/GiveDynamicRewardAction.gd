extends Action
class_name GiveDynamicRewardAction
enum type { NULL = 0,
			ITEM_TAPE = 1,
			BOOTLEG = 2,
			STICKER = 3,
			ITEM_CANDLE = 4,
			ITEM_OPTICAL_LASER = 5}
export (Resource) var fused_material:Resource
export (int) var item_amount:int = 1
export (bool) var passive_message:bool = false
export (Resource) var tape_reward_lootable
export (Array, type) var rewards
export (Array, int) var reward_thresholds 
export (int) var total_value = 100
export (int) var max_num = -1
export (bool) var use_randomiser_mapping:bool = true
export (bool) var show_ui:bool = true

var bootleg_candle = preload("res://data/items/bootleg_ritual_candle.tres")
var optical_laser_tape = preload("res://data/items/tape_optical_laser.tres")
func _run():
	if rewards.size() > 0 and reward_thresholds.size() > 0 and fused_material != null:
		var extra_reward = GetReward()
		var loot:Array = []
		loot += [{"item":fused_material, "amount":item_amount}]
		if extra_reward:
			if extra_reward == type.STICKER:
				loot += GetPartySticker()
			if extra_reward == type.ITEM_CANDLE:
				loot += [{"item":bootleg_candle, "amount":1}]
			if extra_reward == type.ITEM_OPTICAL_LASER:
				loot += [{"item":optical_laser_tape, "amount":1}] 
			if extra_reward == type.ITEM_TAPE:
				loot += tape_reward_lootable.generate_rewards(Random.new(), total_value, max_num)
		var co = MenuHelper.give_items(loot)
		if co is GDScriptFunctionState:
			yield (co, "completed")		
			
		if extra_reward and extra_reward == type.BOOTLEG:
			GiveTape()	
	return true
	
func GetReward():
	var streak = GetWinStreak()
	var index = 0
	for threshold in reward_thresholds:
		if streak == threshold:
			return rewards[index]
		index += 1
	if streak > reward_thresholds[reward_thresholds.size()-1]:
		return rewards[0]
	return null
func GetCurrentCup():
	return SaveState.other_data.RangerArenaProperties["CurrentCup"]
	
func GetWinStreak():
	if GetCurrentCup() == "Debut":
		return SaveState.other_data.RangerArenaProperties["DebutStreak"]	
	if GetCurrentCup() == "Remasters":
		return SaveState.other_data.RangerArenaProperties["RemastersStreak"] 		
	if GetCurrentCup() == "Mix Tapes":
		return SaveState.other_data.RangerArenaProperties["MixTapesStreak"] 
	if GetCurrentCup() == "Bootleg":
		return SaveState.other_data.RangerArenaProperties["BootlegStreak"]
	return 0
	
func GetCupTeam()->Array:
	if GetCurrentCup() == "Debut":
		return SaveState.other_data.RangerArenaProperties["DebutTeam"]	
	if GetCurrentCup() == "Remasters":
		return SaveState.other_data.RangerArenaProperties["RemastersTeam"] 		
	if GetCurrentCup() == "Mix Tapes":
		return SaveState.other_data.RangerArenaProperties["MixTapesTeam"] 
	if GetCurrentCup() == "Bootleg":
		return SaveState.other_data.RangerArenaProperties["BootlegTeam"]
	return []	

func GetPartySticker()->Array:
	var snap = GetCupTeam()
	var result:Array = []
	if snap:
		var tag_list:Array = []
		for tape in snap:
			var form = load(tape.form) as MonsterForm
			for tag in form.move_tags:
				if not tag_list.has(tag):
					tag_list.push_back(tag)
		if tag_list.size() > 0:
			result = generate_rewards(tag_list,Random.new(),100, 4)
	return result


func GiveTape():		
	var rand = Random.new()
	var tape = MonsterTape.new()
	var team = GetCupTeam()

	if team.size() > 0:
		var index = randi()%team.size()
	
		tape.form = load(team[index].form)
		var ElementalTypes = Datatables.load("res://data/elemental_types/")
		var type = rand.choice(ElementalTypes.table.values())
		assert (type is ElementalType)
		tape.type_override = [type]
		
		tape.assign_initial_stickers(true)
		
		yield (MenuHelper.give_tape(tape, not show_ui), "completed")	

func generate_rewards(sticker_tags:Array, rand:Random, _max_value:int, max_num:int = - 1)->Array:
	var rewards = []
	
	var moves:Array
	if sticker_tags.size() == 0:
		moves = BattleMoves.sellable_stickers
	else :
		for tag in sticker_tags:
			moves += BattleMoves.get_moves_for_tag(tag)
	
	assert (moves.size() > 0)
	if moves.size() == 0:
		return []
	
	for i in range(max_num):
		var move = rand.choice(moves)
		var item = ItemFactory.generate_item(move, rand)
		assert (item != null)
		
		if i < max_num:
			item = ItemFactory.upgrade_rarity(item, rand)
			assert (item != null)
			assert (item.rarity >= BaseItem.Rarity.RARITY_UNCOMMON)
		
		rewards.push_back({item = item, amount = 1})
	
	return rewards
