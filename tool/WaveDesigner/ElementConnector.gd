extends Line2D

signal timeIndexChanged

var from
var to
var center: Vector2

var timeIndex: int

func init(timeIndex: = 2):
	self.timeIndex = timeIndex
	var p1 = from.rect_position + Vector2(from.rect_size.x * 0.5, 60)
	var p2 = to.rect_position + Vector2(to.rect_size.x * 0.5, 60)
	add_point(p1)
	add_point(p2)
	center = (p1 + p2) * 0.5
	$PanelContainer / VBoxContainer / HSlider.value = timeIndex
	_on_HSlider_value_changed(timeIndex)
	$PanelContainer.rect_position = center - $PanelContainer.rect_size * 0.5

func _on_HSlider_value_changed(value):
	self.timeIndex = value
	find_node("Label1").text = str(timeIndex) + ":"
	find_node("Label2").text = str(Data.gameProperties.get("monsters.timebetweenmonsters")[value]) + "s"
	emit_signal("timeIndexChanged", timeIndex)
