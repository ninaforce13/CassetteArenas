extends Action
class_name SetArenaAIFusionFlagAction
export (bool) var fusion_flag:bool = true

func _run():
	SaveState.other_data.RangerArenaProperties["FusionSet"] = fusion_flag
	return true
