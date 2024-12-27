extends Reference

class_name Loadout

var domeId: String
var keeperId: String
var primaryGadgetId: String
var gameMode: String
var modeVariant: String

var worldScene: Node2D
var tileData: Node2D
var palette: String

var mapId: String
var worldId: String
var mapArchetype: MapArchetype
var worldModifiers: Array

var generatedMap: = true
var cleanStatePrepared: = false

var savegame = false

func _init(domeId: String, primaryGadgetId: String, keeperId: String, gameMode: String):
	self.domeId = domeId
	self.primaryGadgetId = primaryGadgetId
	self.keeperId = keeperId
	self.gameMode = gameMode

func fixedMap(mapId: String)->Loadout:
	self.mapId = mapId
	generatedMap = false
	return self

func serialize()->Dictionary:
	var data = {
		"domeId": domeId, 
		"primaryGadgetId": primaryGadgetId, 
		"keeperId": keeperId, 
		"gameMode": gameMode, 
		"modeVariant": modeVariant, 
		"mapId": mapId, 
		"worldId": worldId, 
		"palette": palette
	}
	return data
	
func fixedArchetype(mapArchetype: MapArchetype)->Loadout:
	self.mapArchetype = mapArchetype
	return self

func fixedWorld(worldId: String)->Loadout:
	self.worldId = worldId
	return self

func fixedPalette(palette: String)->Loadout:
	self.palette = palette
	return self

func generateModifiers():
	for _j in 10:
		var availableModifiers: Array = Data.worldModifiers.keys().duplicate()
		for mod in GameWorld.lastWorldModifiers:
			availableModifiers.erase(mod)
		worldModifiers = []
		
		var currentRating: = 0
		var consideredModifiers = availableModifiers.duplicate()
		for _i in 3:
			var appliedModId = consideredModifiers[randi() % consideredModifiers.size()]
			worldModifiers.append(appliedModId)
			var appliedMod = Data.worldModifiers[appliedModId]
			currentRating += appliedMod["rating"]
			for modId in availableModifiers.duplicate():
				if Data.worldModifiers[modId]["class"] == appliedMod["class"]:
					availableModifiers.erase(modId)
			
			consideredModifiers.clear()
			for modId in availableModifiers:
				if sign(Data.worldModifiers[modId]["rating"]) != sign(currentRating):
					consideredModifiers.append(modId)
		
		if abs(currentRating) <= 1:
			if GameWorld.devMode:
				print("running with world modifiers " + str(worldModifiers))
			return 

