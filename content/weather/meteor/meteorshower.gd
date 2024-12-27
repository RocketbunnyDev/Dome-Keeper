extends Sprite

const Meteor = preload("res://content/weather/meteor/meteor.tscn")

func _ready():
	Style.init(self)
	start_weather()

func _on_meteorTimer_timeout():
	$meteorTimer.wait_time = rand_range(0.5, 1.5)
	$meteorTimer.start()
	
	var m = Meteor.instance()
	add_child(m)
	
func start_weather():
	
	var possible_positions = get_tree().get_nodes_in_group("weather-meteor")
	if possible_positions.size():
		get_parent().remove_child(self)
		possible_positions[0].add_child(self)
	else:
		queue_free()

func stop():
	var t = Tween.new()
	add_child(t)

	$meteorTimer.stop()
	t.interpolate_callback(self, 3.0, "queue_free")
	t.start()

func pauseChanged():
	$meteorTimer.paused = GameWorld.paused
