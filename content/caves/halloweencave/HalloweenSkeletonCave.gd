extends "res://content/caves/Cave.gd"

var hasSkeleton: = true

func _ready():
	Style.init(find_node("FocusMarker"))
	find_node("Skeleton").playing = true
	
	Level.map.addSpriteToBGAlpha($AlphaMap)
	$Explosion.visible = false

func serialize()->Dictionary:
	var data = .serialize()
	data["hasSkeleton"] = hasSkeleton
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	hasSkeleton = data["hasSkeleton"]
	find_node("Skeleton").visible = hasSkeleton
	if currentState == State.REVEALED:
		find_node("AmbSound").play()

func onRevealed():
	find_node("AmbSound").play()
	find_node("DiscoverySound").play()

func canFocusUse()->bool:
	return hasSkeleton

func useHold(keeper: Keeper):
	return useHit(keeper)

var keeper
func useHit(keeper: Keeper)->bool:
	if not hasSkeleton:
		return false
	
	GameWorld.newSkinsToUnlock.append("skin3")
	self.keeper = keeper
	hasSkeleton = false
	keeper.externallyMoved = true
	keeper.move *= 0
	$Tween.interpolate_property(keeper, "position", keeper.position, $Usable.global_position, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$Tween.interpolate_callback(self, 0.3, "takeSkeleton")
	$Tween.start()
	return true

func _on_Explosion_animation_finished():
	$Explosion.visible = false

func takeSkeleton():
	find_node("ActivatedSound").play()
	keeper.externallyMoved = false
	$Explosion.visible = true
	$Explosion.frame = 0
	$Explosion.playing = true

func _on_Explosion_frame_changed():
	if $Explosion.frame == 2:
		find_node("Skeleton").visible = false
		keeper.setSkin("skin3")
		GameWorld.lastSkinIds[keeper.techId] = "skin3"
		GameWorld.keeperSkinId = "skin3"
