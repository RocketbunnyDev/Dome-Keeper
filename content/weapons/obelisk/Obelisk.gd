extends Node2D

onready var reticle_spawn = $ReticleSpawn.position
const SHOT = preload("res://content/weapons/obelisk/ObeliskShot.tscn")


var maxAmmo: = 1
var ammoUsage: = 1
var fullAuto: = false
var autoReload: = false
var speedWhileReloading: = 0.0
var speedWhileNoAmmo: = 0.0
var shootDelay: = 0.0
var burstDelay: = 0.0
var reloadTime: = 0.0
var minQuickReload: = 0.0
var maxQuickReload: = 0.0
var maxQuickReloadWindow: = 0.0
var maxReticleSpeed: = 0.0
var minReticleSpread: = 0.0
var maxReticleSpread: = 0.0
var guaranteedCenterShotThreshold: = 8.0
var shootingSpread = 0.0
var shootingSpreadDecay = 0.0
var speedWhileShooting = 0.0
var burstCount: = 1
var beamAmmoTickDelay: = 0.25



var is_active: = false
var can_shoot: = true
var can_reload: = false
var is_reloading: = false
var cur_reloadTime: = 0.0
var cur_shootDelay: = 0.0
var cur_burstDelay: = 0.0
var cur_beamAmmoTickDelay: = 0.0
var cur_ammo: = 0
var shoot_button_down_from_shot: = false
var reload_button_down_from_reload: = false
var shoot_button_down_from_reload: = false
var can_increment_quick_reload_attempts: = true
var quick_reload_attempts: = 0
var cur_burstCount = 0
var last_fire: = 0.0
var last_spec: = 0.0

var anticipation_deadzone: = 1.0
var cur_anticipation_deadzone: = 0.0

var min_shoot_delay = 0.05
var max_shoot_delay_reduction: = 0.35
var shoot_delay_reduction_increase: = 0.07000000000000001
var shoot_delay_reduction_decay: = 0.1
var cur_shoot_delay_reduction: = 0.0
var isShootingM: = false
var isShootingA: = false

var beam = null

enum AttackTypes{
	Shot, 
	Beam
}
export (AttackTypes) var attack_type = AttackTypes.Shot



enum ControlModes{
	Keyboard, 
	MouseDrag, 
	MousePing
}
export (ControlModes) var control_mode = ControlModes.Keyboard
var reticle_target: ReticleTarget = null
const RETICLE_TARGET = preload("res://content/weapons/obelisk/ReticleTarget.tscn")
const LIGHTNING_UP = preload("res://content/weapons/obelisk/LightningUp.tscn")







func init(_unusedCupolaPath):
	$Reticle.position = reticle_spawn
	$Reticle.init()
	
	Data.listen(self, "obelisk.maxAmmo", true)
	Data.listen(self, "obelisk.burstCount", true)
	Data.listen(self, "obelisk.fullAuto", true)
	Data.listen(self, "obelisk.autoReload", true)
	Data.listen(self, "obelisk.speedWhileReloading", true)
	Data.listen(self, "obelisk.speedWhileNoAmmo", true)
	Data.listen(self, "obelisk.speedWhileShooting", true)
	Data.listen(self, "obelisk.shootDelay", true)
	Data.listen(self, "obelisk.burstDelay", true)
	Data.listen(self, "obelisk.reloadTime", true)
	Data.listen(self, "obelisk.minQuickReload", true)
	Data.listen(self, "obelisk.maxQuickReload", true)
	Data.listen(self, "obelisk.maxQuickReloadWindow", true)
	Data.listen(self, "obelisk.shootingSpread", true)
	Data.listen(self, "obelisk.shootingSpreadDecay", true)
	Data.listen(self, "obelisk.attackType", true)
	Data.listen(self, "obelisk.ammoUsage", true)
	Data.listen(self, "monsters.wavepresent", true)
	
	
	maxAmmo = Data.of("obelisk.maxAmmo")
	fullAuto = Data.of("obelisk.fullAuto")
	autoReload = Data.of("obelisk.autoReload")
	speedWhileReloading = Data.of("obelisk.speedWhileReloading")
	speedWhileNoAmmo = Data.of("obelisk.speedWhileNoAmmo")
	shootDelay = Data.of("obelisk.shootDelay")
	reloadTime = Data.of("obelisk.reloadTime")
	shootingSpread = Data.of("obelisk.shootingSpread")
	shootingSpreadDecay = Data.of("obelisk.shootingSpreadDecay")
	speedWhileShooting = Data.of("obelisk.speedWhileShooting")
	minQuickReload = Data.of("obelisk.minQuickReload")
	maxQuickReload = Data.of("obelisk.maxQuickReload")
	maxQuickReloadWindow = Data.of("obelisk.maxQuickReloadWindow")
	burstCount = Data.of("obelisk.burstCount")
	burstDelay = Data.of("obelisk.burstDelay")
	attack_type = Data.of("obelisk.attackType")
	ammoUsage = Data.of("obelisk.ammoUsage")
	
	
	$AmmoDisplay.init(maxAmmo)
	ammo_counter_visible(false)
	set_cur_ammo(maxAmmo)
	
	
	init_quick_reload()
	$QuickReload.set_visible(false)
	
	
	
	var target = Level.stage
	var source = $Reticle / ObeliskBeam
	$Reticle.remove_child(source)
	target.add_child(source)
	source.set_owner(target)
	beam = source
	beam.init()
	
	cur_shootDelay = shootDelay
	
	Style.init(self)



func move(dir: Vector2, allowMove: bool = true):
	if not allowMove or GameWorld.paused or not is_active:
		$Reticle.move(Vector2.ZERO, 0.0)
		return 
	
	
	var speed_mod = 1.0
	
	if is_reloading: speed_mod *= speedWhileReloading
	if cur_ammo <= 0 and not is_reloading: speed_mod *= speedWhileNoAmmo
	
	match attack_type:
		AttackTypes.Shot:
			if (($Reticle.cur_spread > $Reticle.maxSpread + shootingSpread * 0.1) and cur_ammo > 0) or isShootingA:
				speed_mod *= speedWhileShooting
				isShootingM = true
			else:
				isShootingM = false
			
		AttackTypes.Beam:
			if (beam.is_active): speed_mod *= speedWhileShooting
	
	$Reticle.move(dir, speed_mod)
	beam.global_position.x = $Reticle.global_position.x
	
	

func action(fireStrength: float, specialStrength: float, allowShoot: bool):
	if not allowShoot or GameWorld.paused or not is_active:
		return 
	
	var fire = fireStrength
	var spec = specialStrength
	
	
	if fire < last_fire:
		fire = 0.0
	if spec < last_spec or ammoUsage == 0:
		spec = 0.0
	
	isShootingA = fire > 0.0
	
	if not shoot_button_down_from_reload:
		match attack_type:
			AttackTypes.Shot:
				action_shot(fire, spec)
			AttackTypes.Beam:
				action_beam(fire, spec)
	
	if fire == 0.0:
		shoot_button_down_from_reload = false
	
	var spec_quick = spec > 0.0 and not reload_button_down_from_reload
	var fire_quick = fire > 0.0 and not shoot_button_down_from_shot and not shoot_button_down_from_reload
	if (spec_quick or fire_quick) and maxQuickReloadWindow > 0.0:
		if quick_reload_attempts == 0:
			var _min = $QuickReload.get_progress_pos_min()
			var _max = $QuickReload.get_progress_pos_max()
			var p = get_reload_progress()
			if p >= _min and p <= _max:
				if fire_quick:
					shoot_button_down_from_reload = true
				reloadFillAmmoQuick()
			elif cur_reloadTime > anticipation_deadzone:
				$QuickReload.set_visible(false)
				if is_reloading and not $QuickReloadFail.playing:
					$QuickReloadFail.play()
			elif cur_reloadTime <= anticipation_deadzone:
				quick_reload_attempts -= 1
		else:
			$QuickReload.set_visible(false)
		
		if can_increment_quick_reload_attempts:
			quick_reload_attempts += 1
			can_increment_quick_reload_attempts = false
	
	
	if spec > 0.0 and can_reload and not is_reloading:
		reloadStart()
		reload_button_down_from_reload = true
	
	if spec == 0.0:
		reload_button_down_from_reload = false
		can_increment_quick_reload_attempts = true
	
	if fire == 0.0:
		shoot_button_down_from_shot = false
		shoot_button_down_from_reload = false
	
	
	if fire > 0.0 and not autoReload and cur_ammo <= 0 and not shoot_button_down_from_shot and not is_reloading:
		reloadStart()
	
	
	if fire > 0.0 and not shoot_button_down_from_shot and not shoot_button_down_from_reload and last_fire != fire:
		if cur_reloadTime > 0.0 and quick_reload_attempts > 2:
			$DenialSound.play(0.0)
		elif cur_shootDelay > 0.0 and cur_shootDelay < shootDelay:
			$DenialSound.play(0.0)
	
	if not fullAuto and fire == 0.0:
		shoot_button_down_from_shot = false
	
	last_fire = fireStrength
	last_spec = specialStrength




func action_shot(fire, spec):
	if fire > 0.0 and can_shoot and cur_ammo > 0 and not is_reloading and not shoot_button_down_from_reload:
		if not fullAuto:
			if not shoot_button_down_from_shot:
				shoot()
				shoot_button_down_from_shot = true
		else:
			shoot()
			shoot_button_down_from_shot = true

func action_beam(fire, spec):
	if fire > 0.0 and can_shoot and cur_ammo > 0 and not is_reloading and not shoot_button_down_from_reload:
		beam.set_is_active(true)
		shoot_button_down_from_shot = true
	else:
		beam.set_is_active(false)



func propertyChanged(property: String, oldValue, newValue):
	match property:
		"obelisk.maxammo":
			maxAmmo = newValue
			$AmmoDisplay.init(maxAmmo)
			set_cur_ammo(maxAmmo)
		"obelisk.burstcount":
			burstCount = newValue
		"obelisk.fullauto":
			fullAuto = newValue
		"obelisk.autoreload":
			autoReload = newValue
		"obelisk.speedwhilereloading":
			speedWhileReloading = newValue
		"obelisk.speedwhilenoammo":
			speedWhileNoAmmo = newValue
		"obelisk.speedwhileshooting":
			speedWhileShooting = newValue
		"obelisk.shootdelay":
			shootDelay = newValue
		"obelisk.burstdelay":
			burstDelay = newValue
		"obelisk.reloadtime":
			reloadTime = newValue
			init_quick_reload()
			if anticipation_deadzone > 0.5 * reloadTime:
				anticipation_deadzone = reloadTime * 0.5
			else:
				anticipation_deadzone = 1.0
		"obelisk.minquickreload":
			minQuickReload = newValue
			init_quick_reload()
		"obelisk.maxquickreload":
			maxQuickReload = newValue
			init_quick_reload()
		"obelisk.maxquickreloadwindow":
			maxQuickReloadWindow = newValue
			init_quick_reload()
		"obelisk.shootingspread":
			shootingSpread = newValue
		"obelisk.shootingspreaddecay":
			shootingSpreadDecay = newValue
		"obelisk.attacktype":
			attack_type = newValue
		"obelisk.ammousage":
			ammoUsage = newValue
		
		
		"monsters.wavepresent":
			if oldValue != newValue:
				
				
				set_cur_ammo(maxAmmo)


func _process(delta: float)->void :
	if not (isShootingA or isShootingM):
		cur_shoot_delay_reduction -= shoot_delay_reduction_decay * delta
		cur_shoot_delay_reduction = max(cur_shoot_delay_reduction, 0)
	
	if $Reticle.shooting_spread > 0:
		$Reticle.shooting_spread = max(0, $Reticle.shooting_spread - shootingSpreadDecay)
	if burstCount == 1:
		if cur_shootDelay < max(shootDelay - cur_shoot_delay_reduction, min_shoot_delay):
			cur_shootDelay += delta
		else:
			if not $ReadyLightning.playing and not can_shoot and not is_reloading:
				if $ReadyLightning.stream.get_length() < shootDelay:
					$ReadyLightning.play()
			can_shoot = true
	else:
		if cur_burstCount >= burstCount:
			if cur_shootDelay < shootDelay:
				cur_shootDelay += delta
			else:
				if not $ReadyLightning.playing and not can_shoot and not is_reloading:
					if $ReadyLightning.stream.get_length() < shootDelay:
						$ReadyLightning.play()
				can_shoot = true
				cur_burstCount = 0
		else:
			if cur_burstDelay < burstDelay:
				cur_burstDelay += delta
			else:
				if cur_burstCount > 0 and cur_burstCount < burstCount:
					
					shoot()
					cur_burstDelay = 0.0
				elif cur_burstCount >= burstCount:
					if not $ReadyLightning.playing and not can_shoot and not is_reloading:
						if $ReadyLightning.stream.get_length() < shootDelay:
							$ReadyLightning.play()
					can_shoot = true
					cur_burstCount = 0
					cur_burstDelay = 0.0
			
		
	if is_reloading:
		if cur_anticipation_deadzone < anticipation_deadzone:
			cur_anticipation_deadzone += delta
		else:
			var progress = get_reload_progress()
			$QuickReload.show_progress(progress)
			$Reticle.apply_shoot_delay(1.0)
			$ReloadStaticSound.pitch_scale = 1.0 + (progress)
			$ReloadStaticSound.volume_db = - 2 - (progress) * 10
			
	else:
		$Reticle.apply_shoot_delay(cur_shootDelay / max(shootDelay - cur_shoot_delay_reduction, min_shoot_delay))
	
	if cur_reloadTime < reloadTime and cur_reloadTime > 0.0:
		cur_reloadTime += delta
	if cur_reloadTime >= reloadTime:
		reloadFillAmmo()
	
	if attack_type == AttackTypes.Beam and beam.is_active:
		if cur_beamAmmoTickDelay < beamAmmoTickDelay:
			cur_beamAmmoTickDelay += delta
		else:
			cur_beamAmmoTickDelay = 0.0
			set_cur_ammo(cur_ammo - ammoUsage)
			if autoReload and cur_ammo <= 0:
				reloadStart()
	
func get_reload_progress():
	var p = max(0, cur_reloadTime - anticipation_deadzone) / reloadTime
	p *= 1.0 + anticipation_deadzone / reloadTime
	return p

func start():
	$TweenReturnReticle.remove_all()
	set_is_active(true)
	ammo_counter_visible(true)
	
	
	if control_mode == ControlModes.MousePing:
		ping_reticle_target(reticle_spawn)
	
	$StartSound.play()
	
	if is_reloading:
		$QuickReload.set_visible(true)


func stop():
	return_reticle()
	set_is_active(false)
	ammo_counter_visible(false)
	
	$StopSound.play()

func ammo_counter_visible(visiblee: bool):
	$AmmoDisplay.visible = visiblee and ammoUsage > 0

func return_reticle():
	$TweenReturnReticle.remove_all()
	var dist = ($ReticleSpawn.global_position - $Reticle.global_position).length()
	
	var anim_time = 0.01 * dist
	
	$TweenReturnReticle.interpolate_property($Reticle, "position", $Reticle.position, reticle_spawn, anim_time, Tween.TRANS_BACK)
	$TweenReturnReticle.interpolate_method($Reticle, "apply_spread", $Reticle.cur_spread, 0, anim_time, Tween.TRANS_BACK)
	$TweenReturnReticle.start()

func init_quick_reload():
	var _min = minQuickReload
	var _max = maxQuickReload
	
	if (_max - _min) * reloadTime > maxQuickReloadWindow:
		var max_span = _min + (maxQuickReloadWindow / reloadTime)
		_max = max_span
		maxQuickReload = _max
	$QuickReload.init(_min, _max)

func set_is_active(value: bool):
	is_active = value
	
	if control_mode == ControlModes.MouseDrag:
		if is_active:
			var tar = RETICLE_TARGET.instance()
			tar.init(false)
			add_child(tar)
			reticle_target = tar
			$Reticle.cur_reticle_target = tar
			$Reticle.follow_reticle_target = true
		else:
			$Reticle.follow_reticle_target = false
			$Reticle.cur_reticle_target = null
			reticle_target.queue_free()
			reticle_target = null
	
	$Reticle.is_active = is_active
	$QuickReload.set_visible(false)

func shoot():
	if GameWorld.paused or not is_active:
		return 
	$Reticle.shooting_spread = shootingSpread
	can_shoot = false
	cur_shootDelay = 0.0
	cur_burstCount += 1
	set_cur_ammo(cur_ammo - ammoUsage)
	
	if autoReload and cur_ammo <= 0:
		reloadStart()
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	
	var newShot = SHOT.instance()
	var rand_pos = Vector2.ZERO
	if $Reticle.cur_spread > guaranteedCenterShotThreshold:
		rand_pos = Vector2(rand_range(0, $Reticle.cur_spread), 0).rotated(rand_range(0, 6.28))
	var final_pos = $Reticle.global_position + rand_pos
	newShot.global_position = final_pos
	newShot.init()
	Level.stage.add_child(newShot)
	
	light_up_crosshair()
	arc_to_shot(final_pos)
	
	if fullAuto and attack_type == AttackTypes.Shot:
		cur_shoot_delay_reduction += shoot_delay_reduction_increase
		cur_shoot_delay_reduction = clamp(cur_shoot_delay_reduction, 0, max_shoot_delay_reduction)

func light_up_crosshair():
	$TweenShoot.interpolate_property($Reticle.get_node("CrosshairContainer"), "modulate", Color(15.0, 15.0, 15.0, 1.0), Color(1.0, 1.0, 1.0, 1.0), 0.5, Tween.TRANS_LINEAR)
	$TweenShoot.start()

func arc_to_shot(shotPosition: Vector2):
	
	var up = LIGHTNING_UP.instance()
	var x = $ReticleSpawn.global_position.x + shotPosition.x * Data.of("obelisk.lightningXRatio")
	var y = Data.of("obelisk.lightningYTarget")
	var target = Vector2(x, y)
	up.init()
	up.position = reticle_spawn
	Level.stage.add_child(up)
	up.look_at(target)
	$LightningUpSound.play()

func set_is_reloading(value: bool):
	is_reloading = value
	if is_reloading:
		$ReloadStaticSound.play()
	else:
		$ReloadStaticSound.stop()
	
	cur_burstDelay = 0.0
	cur_burstCount = 0
	

func reloadStart():
	quick_reload_attempts = 0
	set_is_reloading(true)
	cur_reloadTime = 0.01
	$AmmoDisplay.empty_ammo()
	$QuickReload.set_visible(true)
	$QuickReload.show_progress(0.0)
	reticle_reload_anim()
	$ReloadStartSound.play()
	if attack_type == AttackTypes.Beam:
		beam.set_is_active(false)
		
	cur_shoot_delay_reduction = 0.0

func reloadFillAmmo(play_sfx: = true):
	can_shoot = true
	set_is_reloading(false)
	set_cur_ammo(maxAmmo)
	cur_reloadTime = 0.0
	$AmmoDisplay.fill_ammo()
	$QuickReload.set_visible(false)
	if play_sfx:
		$ReloadFinishSound.play()
	cur_anticipation_deadzone = 0.0

func reloadFillAmmoQuick(play_sfx: = true):
	$TweenReload.seek($TweenReload.get_runtime())
	if play_sfx:
		$QuickReloadSuccess.play()
	reloadFillAmmo(false)

func set_cur_ammo(value: int):
	cur_ammo = value
	$AmmoDisplay.set_current_ammo(cur_ammo)
	can_reload = cur_ammo < maxAmmo

func reticle_reload_anim():
	$TweenReload.remove_all()
	$TweenReload.interpolate_method($Reticle, "apply_spread", $Reticle.cur_spread, 0, 0.2, Tween.TRANS_BACK)
	$TweenReload.interpolate_property($Reticle.get_node("CrosshairContainer"), "rotation_degrees", 0, 360 * (round(reloadTime) + 1), reloadTime, Tween.TRANS_CUBIC)
	$TweenReload.start()








func ping_reticle_target(target_pos: Vector2):
	if is_instance_valid(reticle_target):
		reticle_target.decrement_blockers()
	var tar = RETICLE_TARGET.instance()
	tar.init(true)
	tar.global_position = target_pos
	add_child(tar)
	reticle_target = tar
	$Reticle.cur_reticle_target = tar
	$Reticle.follow_reticle_target = true
