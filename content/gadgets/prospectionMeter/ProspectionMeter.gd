extends HudElement








var unlockedMeters: = [CONST.IRON]
var unlockedNeedles: = []
var tilesToScan: = {}

var meterSpots: = [3, 10, 17]
onready var meters: = [$Iron1, $Water1, $Sand1]

func init():
	tilesToScan[Data.TILE_IRON] = []
	$Iron1.visible = true
	$Water1.visible = false
	$Sand1.visible = false
	$Compass.visible = false
	$Compass / NeedleIron.visible = false
	$Compass / NeedleSand.visible = false
	$Compass / NeedleWater.visible = false
	Data.listen(self, "prospectionmeter.iron")
	Data.listen(self, "prospectionmeter.water")
	Data.listen(self, "prospectionmeter.sand")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"prospectionmeter.iron":
			if newValue == 2:
				unlockedNeedles.append(CONST.IRON)
				$Compass / NeedleIron.visible = true
				$Compass.visible = true
		"prospectionmeter.water":
			if newValue == 2:
				unlockedNeedles.append(CONST.WATER)
				$Compass / NeedleWater.visible = true
				$Compass.visible = true
			elif newValue == 1:
				unlockedMeters.append(CONST.WATER)
				$Water1.visible = true
				tilesToScan[Data.TILE_WATER] = []
		"prospectionmeter.sand":
			if newValue == 2:
				unlockedNeedles.append(CONST.SAND)
				$Compass / NeedleSand.visible = true
				$Compass.visible = true
			elif newValue == 1:
				unlockedMeters.append(CONST.SAND)
				$Sand1.visible = true
				tilesToScan[Data.TILE_SAND] = []
	updateSize()

func updateSize():
	var needle = min(unlockedNeedles.size(), 1)
	size.y = max(1 + unlockedMeters.size(), needle * 4)
	size.x = 4 + needle * 4
	
	var i: = 0
	for m in meters:
		if m.visible:
			m.rect_position.y = meterSpots[i]
			i += 1
	
	emit_signal("request_rebuild")

func _process(delta: float)->void :
	if visible:
		for r in tilesToScan:
			tilesToScan[r].clear()
		var radius: int = Data.of("prospectionMeter.range")
		var keeperCoord = Level.map.getTileCoord(Level.keeper.global_position)
		for x in range( - radius, radius + 1):
			for y in range( - radius, radius + 1):
				if abs(x) + abs(y) > radius:
					continue
				var res = Level.map.tileData().get_resource(keeperCoord.x + x, keeperCoord.y + y)
				if tilesToScan.has(res):
					var tileOffset = Vector2(x, y)
					tilesToScan[res].append(tileOffset)
		
		for res in tilesToScan:
			var best = null
			var dist = 9999999
			for tileOffset in tilesToScan[res]:
				var d = tileOffset.length()
				if d < dist:
					dist = d
					best = tileOffset
			
			var type = Map.TYPE_MAP.get(res)
			var meter = find_node(type.capitalize() + "Meter")
			if best:
				var floatDist = Level.map.getTilePos(keeperCoord + best) - Level.keeper.global_position
				meter.goalFilling = 1.0 - clamp((floatDist.length() - GameWorld.TILE_SIZE) / float(radius * GameWorld.TILE_SIZE), 0.0, 1.0)
				if unlockedNeedles.has(type):
					var goalDir = PI * 0.25 + (best.position - Level.keeper.position).angle()
					find_node("Needle" + res.capitalize()).goalDir = rad2deg(goalDir)
			else:
				meter.goalFilling = 0.0
