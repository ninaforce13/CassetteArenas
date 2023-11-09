extends Node
class_name SmartBuffAI

export (Resource) var move:Resource
export (bool) var only_if_target_is_self:bool = false
export (bool) var only_if_target_is_ally:bool = false
export (bool) var only_if_target_is_self_or_ally:bool = false
export (bool) var only_if_target_is_enemy:bool = false
export (Resource) var only_if_user_has_type:Resource
export (Array, String) var only_if_target_has_status_tag:Array
export (Array, String) var only_if_target_lacks_status_tag:Array
export (Array, String) var only_if_user_has_status_tag:Array
export (String) var only_if_enemy_has_status_tag:String
export (Array, Resource) var only_if_target_has_type:Array
export (Array, Resource) var only_if_target_lacks_type:Array
export (Resource) var only_if_status_due_to_run_out:Resource
export (int, 0, 101) var only_if_target_hp_percent_below:int = 101
export (float) var score:float = 1.0
export (int, "Absolute", "Add", "Multiply") var score_mode:int = 0

func get_order_score(order:BattleOrder, current_score:float)->float:
	if matches_conditions(order):
		return modify_score(current_score)
	return current_score

func matches_conditions(order:BattleOrder)->bool:
	var battle = get_parent().battle
	var fighter = get_parent().fighter
	
	var targets = []
	if order.argument.has("target_slots"):
		for slot in order.argument.target_slots:
			var target = slot.get_fighter()
			if target != null:
				targets.push_back(target)
	if targets.size() == 0:
		targets.push_back(fighter)
	
	if move and not move.is_move(order.order):
		return false
	if only_if_target_is_self and not (fighter in targets):
		return false
	if only_if_target_is_ally and (targets[0].team != fighter.team or targets == [fighter]):
		return false
	if only_if_target_is_self_or_ally and targets[0].team != fighter.team:
		return false
	if only_if_target_is_enemy and targets[0].team == fighter.team:
		return false
	if only_if_user_has_type:
		if not fighter.status.get_types().has(only_if_user_has_type):
			return false
	if only_if_target_has_status_tag.size() != 0:
		var has_tag = false
		for tag in only_if_target_has_status_tag:
			if targets[0].status.has_tag(tag):
				has_tag = true
				break
		if not has_tag:
			return false
	if only_if_target_lacks_status_tag.size() != 0:
		var has_tag = false
		for tag in only_if_target_lacks_status_tag:
			if targets[0].status.has_tag(tag):
				has_tag = true
				break
		if has_tag:
			return false
	if only_if_user_has_status_tag.size() != 0:
		var has_tag = false
		for tag in only_if_user_has_status_tag:
			if fighter.status.has_tag(tag):
				has_tag = true
				break
		if not has_tag:
			return false
	if only_if_enemy_has_status_tag != "":
		var has_tag = false
		for enemy in battle.get_fighters():
			if enemy.team == fighter.team:
				continue
			if enemy.status.has_tag(only_if_enemy_has_status_tag):
				has_tag = true
				break
		if not has_tag:
			return false
	if only_if_target_has_type.size() != 0:
		var has_type = false
		for type in only_if_target_has_type:
			if targets_have_type(targets, type):
				has_type = true
				break
		if not has_type:
			return false
	if only_if_target_lacks_type.size() != 0:
		var has_type = false
		for type in only_if_target_has_type:
			if targets_have_type(targets, type):
				has_type = true
				break
		if has_type:
			return false
	if only_if_status_due_to_run_out:
		var applicable = false
		for target in targets:
			var node = target.status.get_effect_node(only_if_status_due_to_run_out)
			if node:
				var target_speed = target.slot.form.speed
				var user_speed = fighter.slot.form.speed
				print("Cassette Arenas: Haunt duration left is " +  str(node.amount))
				print("Cassette Arenas: Target speed is " + str(target_speed))
				print("Cassette Arenas: User speed is " + str(user_speed))
				print("Cassette Arenas: Target is faster = " + str(target_speed>=user_speed))
				if (not node.everlasting) and ( node.amount == 1 or (target_speed >= user_speed and node.amount <= 2)):
					print("Cassette Arenas: Removing Haunt a turn early due to speed difference")
					applicable = true
					break
		if not applicable:
			return false
	
	if only_if_target_hp_percent_below < 101:
		var any_below = false
		for target in targets:
			if target.status.hp * 100 / target.status.max_hp < only_if_target_hp_percent_below:
				any_below = true
				break
		if not any_below:
			return false
	
	return true

func targets_have_type(targets:Array, type:ElementalType)->bool:
	for target in targets:
		if target.status.get_types().has(type):
			return true
	return false

func modify_score(value:float)->float:
	if score_mode == 0:
		return score
	elif score_mode == 1:
		return score + value
	else :
		assert (score_mode == 2)
		return score * value
