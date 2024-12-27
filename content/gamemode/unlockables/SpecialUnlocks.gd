extends Container

func _ready():
	if not GameWorld.won or GameWorld.buildType == CONST.BUILD_TYPE.EXHIBITION:
		visible = false
		return 
	
	var newDifficulty: bool = false
	if GameWorld.difficulty == 0:
		newDifficulty = GameWorld.unlockElement(CONST.DIFFICULTY_YAFI) != ""
	
	var newWorld: bool = false
	var nextWorld = GameWorld.nextUnlock(GameWorld.worldId)
	if nextWorld and GameWorld.unlockElement(nextWorld) != "":
		newWorld = true
		var id = nextWorld.to_upper() + "_UNLOCK"
		Achievements.triggerIfOpen(id)
	
	var newMapSize: bool = false
	var nextMapSize = GameWorld.nextUnlock(GameWorld.lastMapSize)
	if nextMapSize and GameWorld.unlockElement(nextMapSize) != "":
		newMapSize = true
	
	var newPet: = false
	for p in get_tree().get_nodes_in_group("pets"):
		if not GameWorld.unlockedPets.has(p.id):
			GameWorld.unlockablePets.erase(p.id)
			GameWorld.unlockedPets.append(p.id)
			newPet = true
	
	var newSkin: = false
	for skin in GameWorld.newSkinsToUnlock:
		if not GameWorld.unlockedSkins.get(GameWorld.lastKeeperId, []).has(skin):
			GameWorld.unlockSkin(GameWorld.lastKeeperId, skin)
			newSkin = true
	
	GameWorld.persistMetaState()
	
	find_node("NewDifficultyUnlockedPanel").visible = newDifficulty
	find_node("NewWorldUnlockedPanel").visible = newWorld
	find_node("NewMapSizeUnlockedPanel").visible = newMapSize
	find_node("NewPetUnlockedPanel").visible = newPet
	find_node("SkinUnlockPanel").visible = newSkin
	
	var visiblePanels: = []
	if newDifficulty:
		visiblePanels.append(find_node("NewDifficultyUnlockedPanel"))
	if newWorld:
		visiblePanels.append(find_node("NewWorldUnlockedPanel"))
	if newMapSize:
		visiblePanels.append(find_node("NewMapSizeUnlockedPanel"))
	if newPet:
		visiblePanels.append(find_node("NewPetUnlockedPanel"))
	if newSkin:
		visiblePanels.append(find_node("SkinUnlockPanel"))
	
	find_node("ModifiersUnlockedPanel").visible = false
	if visiblePanels.size() <= 1:
		if GameWorld.unlockElement("world-modifiers") != "":
			visiblePanels.append(find_node("ModifiersUnlockedPanel"))
	
	var delay: = 1.0
	for panel in visiblePanels:
		delay += animateUpdate(panel, delay)

const medalScale: = 1.8
func animateUpdate(panel, delay: float)->float:
	var duration1 = 0.5
	var duration2 = 0.15
	
	panel.rect_scale = Vector2.ZERO
	panel.modulate.a = 0.0
	

	$Tween.interpolate_callback(panel, delay, "set", "modulate", Color.white)
	panel.rect_pivot_offset = panel.get_size() * 0.5
	


	$Tween.interpolate_property(panel, "rect_scale", Vector2.ZERO, Vector2.ONE * medalScale, duration1, Tween.TRANS_CUBIC, Tween.EASE_OUT, delay)
	$Tween.interpolate_property(panel, "rect_scale", Vector2.ONE * medalScale, Vector2.ONE, duration2, Tween.TRANS_CUBIC, Tween.EASE_IN, delay + duration1)
	$Tween.interpolate_callback(Audio, delay + duration1 + 0.0, "sound", "unlock_event")
	$Tween.start()
	
	return duration1 + duration2 + 0.4
