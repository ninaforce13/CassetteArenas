extends Action
class_name ShowUnlockBanner
export (String) var ability:String = "The Cassette Arena"

func _run():
	var banner = preload("res://mods/RangerArena/UI/UnlockedArenaBanner.tscn").instance()
	banner.ability = ability
	MenuHelper.add_child(banner)
	yield (banner.run_menu(), "completed")
	banner.queue_free()
	return true
