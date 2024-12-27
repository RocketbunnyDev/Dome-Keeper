extends Path2D

const TOTAL_SHARDS = 40
const Shard = preload("res://content/dome/collapse/Shard.tscn")

func collapse():
	
	
	var points = curve.get_baked_points()
	var size = points.size()
	for i in range(TOTAL_SHARDS):
		var p = points[randi() % size]
		var s = Shard.instance()
		s.position = p
		add_child(s)
		if i % 5 == 0:
			yield (get_tree(), "idle_frame")

