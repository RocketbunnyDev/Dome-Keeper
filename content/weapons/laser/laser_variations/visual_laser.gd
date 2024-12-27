extends Node2D
class_name Laser

var endpoint: Vector2 setget set_endpoint, get_endpoint

func _ready():
	if has_node("MuzzleFlash"):
		$MuzzleFlash.play("glow")
	
	Style.init(self)

func target(pos):
	set_endpoint(pos)
	
func get_endpoint():
	return endpoint
	
func set_endpoint(value):
	endpoint = value
	for child in get_children():
		if child is Sprite:
			(child as Sprite).region_rect.size.x = endpoint.length()
			
func start():
	for child in get_children():
		if child is Sprite or child is AnimatedSprite:
			child.show()
	if has_node("Burst"):
		$Burst.frame = 0
		$Burst.play("kapow")
	if not $FireSound.playing:
		$FireSound.play()
	$FireSoundInit.play()

func stop():
	for child in get_children():
		if child is Sprite or child is AnimatedSprite:
			child.hide()
	$FireSoundInit.stop()
	$FireSound.stop()
	
	$FireSoundStop.play()
	stop_hit()
	
func start_hit(where):
	$HitEffect.position = where
	$HitParticles.position = where
	if not $HitParticles.emitting:
		$HitParticles.emitting = true
		$HitEffect.visible = true
		$FireMonsterHit.play()
	
func stop_hit():
	$HitParticles.emitting = false
	$HitEffect.visible = false
	$FireMonsterHit.stop()

func playHitBumpSound():
	if not $HitParticles.emitting:
		$FireMonsterBump.play()
	
