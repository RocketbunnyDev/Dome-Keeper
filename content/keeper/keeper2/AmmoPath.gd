extends Node2D

var currentRotation: = 0.0

func _ready():
	Data.listen(self, "keeper2.remainingspheres")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"keeper2.remainingspheres":
			var childCount = $AmmoPath.get_child_count()
			if newValue > childCount:
				var ammo = preload("res://content/keeper/keeper2/Ammo.tscn").instance()
				if childCount > 0:
					ammo.unit_offset = fmod(currentRotation + 1.0 / float(childCount), 1.0)
				$AmmoPath.add_child(ammo)
				ammo.find_node("AnimatedSprite").playing = true
				Style.init(ammo)
				$AmmoAdded.play()
			elif newValue < childCount and childCount > 0:
				$AmmoPath.get_child(0).queue_free()

func _process(delta):
	var relativeMove = get_parent().move / get_parent().currentSpeed()
	relativeMove *= pow(relativeMove.length(), 2)
	var goalPos = relativeMove * - 20
	var moveDelta = (goalPos - position).clamped(4.0)
	position += moveDelta * 5 * delta
	scale = scale - (scale - Vector2.ONE * max(0.2, (1.0 - relativeMove.length()))) * delta * 2.0
	
	currentRotation += delta * 0.25 * (5 * get_parent().ballCharge + max(0.0, 1.0 - position.length() * 0.033))
	if currentRotation > 1.0:
		currentRotation = 0.0
	
	var thresh = 0.75
	if get_parent().ballCharge > thresh:
		var alpha = ((get_parent().ballCharge - thresh) * 1.0 / (1.0 - thresh)) * 1.0
		$AmmoSpin.modulate.a = ease(alpha, 2.0)
		$AmmoPath.modulate.a = 1.0 - ease(alpha, 2.0)
		$AmmoSpin.play("spin")
		$AmmoSpin.show()
		$AmmoSpin.rotation = - currentRotation * TAU
	else:
		$AmmoPath.modulate.a = 1.0
		$AmmoSpin.hide()
	
	var childCount = $AmmoPath.get_child_count()
	if childCount > 0:
		var step = 1.0 / float(childCount)
		for i in range(0, childCount):
			var child = $AmmoPath.get_child(i)
			child.scale = Vector2.ONE / scale
			var goalOffset = fmod(currentRotation + step * i, 1.0)
			var offsetDelta = goalOffset - child.unit_offset
			if offsetDelta < 0.0:
				offsetDelta += 1.0
			child.unit_offset += offsetDelta * delta * 2.0
