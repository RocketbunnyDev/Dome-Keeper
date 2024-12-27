extends Node2D


var min_bound: = 0.0
var max_bound: = 0.0

var bar_length: = 0

func init(minBound: float, maxBound: float):
	bar_length = $QuickReloadBar.texture.get_size().x - 6
	
	min_bound = minBound
	max_bound = maxBound
	
	$MinBound.position.x = position_on_slider(min_bound)
	$MaxBound.position.x = position_on_slider(max_bound)
	$MinBound.visible = min_bound != max_bound
	$MaxBound.visible = min_bound != max_bound
	
	$QuickReloadWindowSquash.position.x = position_on_slider((min_bound + max_bound) / 2)
	$QuickReloadWindowSquash.scale.x *= (max_bound - min_bound)
	
	show_progress(0.0)
	
	Style.init(self)


func show_progress(progress: float):
	$SliderSprite.position.x = position_on_slider(progress, false)

func position_on_slider(progress: float, _round: = true):
	var result = progress * bar_length
	result -= bar_length * 0.5
	if _round:
		result = round(result)
	return result

func set_visible(value: bool):
	if Data.of("obelisk.maxQuickReloadWindow") <= 0.0 or Data.of("obelisk.maxQuickReload") == Data.of("obelisk.minQuickReload"):
		visible = false
	else:
		visible = value

func get_progress_pos_min()->float:
	return ($MinBound.position.x + bar_length * 0.5) / bar_length
func get_progress_pos_max()->float:
	return ($MaxBound.position.x + bar_length * 0.5) / bar_length
