extends Area2D

var coolDown: = 0.0

var drops: = []

func getDeliverableDrop(type: String):
	var p = get_parent()
	if not p.absorbed and p.type == type:
		return p
	else:
		return null

func _process(delta):
	if coolDown > 0.0:
		coolDown -= delta
	if coolDown <= 0.0 and drops.size() > 0:
		var closestDistance: float = 9999
		var closestDrop
		for drop in drops:
			if not drop.isCarried() and not drop.absorbed:
				
				
				var l = getDistance(drop)
				if l < closestDistance:
					closestDistance = l
					closestDrop = drop
		if closestDrop:
			coolDown = 1.0
			shredDrop(closestDrop)


func getDistance(drop)->float:
	return (drop.global_position - $ShredPoint.global_position).length()

func shredDrop(drop):
	drop.shred()
	drops.erase(drop)
	$Sprite.frame = 0
	$Sprite.play("running")
	var shred2 = $ShredPoint / ShredSound.duplicate()
	shred2.removeAfterPlaying = true
	add_child(shred2)
	shred2.play()

func _on_Shredder_area_entered(area):
	for r in ["iron", "water", "sand"]:
		var drop = area.getDeliverableDrop(r)
		if drop:
			drop.floatToDropTarget(self)
			return 

func dropTarget()->Vector2:
	return $ShredPoint.global_position

func arrived(drop):
	if not drops.has(drop):
		drops.append(drop)
