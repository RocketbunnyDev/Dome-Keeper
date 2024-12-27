extends AudioStreamPlayer






const BUS_MASTER: = "Master"
const BUS_MUSIC: = "Music"
const BUS_AMBIENCE: = "Ambience"
const BUS_UI: = "UI"
const BUS_SOUNDS: = "Sounds"
const BUS_SHIELD: = "Shield"
const BUS_CRITICAL: = "Critical"
const BUS_MINE: = "Mine"
const BUS_WORLD: = "World"
const BUS_KEEPER: = "Keeper"

const AMBIENCE_FADE_TIME: = 1.8

var upgrade = preload("res://content/sounds/UI/TechUpgrade.wav")
var upgradeMax = preload("res://content/sounds/Bastards/sfx_kick03.wav")

var gui_select = preload("res://content/sounds/UI/Select.wav")
var gui_select_upgrade = preload("res://content/sounds/UI/Gadgethcoose.wav")
var gui_hover = preload("res://content/sounds/UI/TechHover.wav")
var gui_back = preload("res://content/sounds/UI/Back.wav")
var gui_cancel = preload("res://content/sounds/UI/Cancel.wav")
var gui_toggle = preload("res://content/sounds/UI/Toggle.wav")
var gui_err = preload("res://content/sounds/UI/Error.wav")
var gui_move = preload("res://content/sounds/UI/Cycle_short.wav")

var gui_tutorial_in = preload("res://content/sounds/UI/TutorialUI.wav")
var gui_cheats = preload("res://content/sounds/UI/plastic building_03.wav")

var gui_title_credits = preload("res://content/sounds/UI/Credits.wav")
var gui_title_continue = preload("res://content/sounds/UI/ContinueGame.wav")
var gui_title_newgame = preload("res://content/sounds/UI/NewGame.wav")
var gui_title_options = preload("res://content/sounds/UI/Settings.wav")

var gui_unlock_upgrade = preload("res://content/sounds/UI/UnlockUpgrade.wav")

var gui_start_game = preload("res://content/sounds/UI/StartGameConfirm.wav")

var gui_pause_start = preload("res://content/sounds/UI/Pause.wav")
var gui_pause_stop = preload("res://content/sounds/UI/Unpause.wav")

var gui_quit_ask = preload("res://content/sounds/UI/Quit.wav")
var gui_quit_confirm = preload("res://content/sounds/UI/QuitAreYouSure.wav")
var gui_quit_toggle = preload("res://content/sounds/UI/Toggle.wav")

var gui_tab = preload("res://content/sounds/UI/SettingsTab.wav")
var gui_slider = preload("res://content/sounds/UI/ui_slider.wav")
var tech_hover = preload("res://content/sounds/UI/TechHover.wav")

var stinger_relic_chamber_excavated_keeper1 = preload("res://content/sounds/stingers/ENGINEER Relic1.ogg")
var stinger_gadget_chamber_excavated_keeper1 = preload("res://content/sounds/stingers/ENGINEER Gadget1.ogg")
var stinger_relic_chamber_excavated_keeper2 = preload("res://content/sounds/stingers/ASSESSOR Relic.ogg")
var stinger_gadget_chamber_excavated_keeper2 = preload("res://content/sounds/stingers/ASSESSOR Gadget.ogg")

var enter_station_dome1 = preload("res://content/sounds/dome1/sfx_computer_01.wav")
var enter_station_dome2 = preload("res://content/sounds/dome2/Dome2_Enter2.wav")
var enter_station_dome4 = preload("res://content/sounds/dome4/ObeliskDomeenter_1.wav")
var charge_on_dome1 = preload("res://content/sounds/dome1/Terminal01_BattleButton.wav")
var charge_on_dome2 = preload("res://content/sounds/dome2/DomeTerminal2_04.wav")
var charge_on_dome4 = preload("res://content/sounds/dome4/ObeliskDomeenter.wav")
var charge_off_dome1 = preload("res://content/sounds/dome1/Terminal01_Open.wav")
var charge_off_dome2 = preload("res://content/sounds/dome2/DomeTerminal2_05.wav")
var charge_off_dome4 = preload("res://content/sounds/dome2/DomeTerminal2_05.wav")
var exit_station_dome1 = preload("res://content/sounds/dome1/Terminal01_Exitt.wav")
var exit_station_dome2 = preload("res://content/sounds/dome2/Dome2_Exit.wav")
var exit_station_dome4 = preload("res://content/sounds/dome4/domeexit.wav")
var open_upgrades = preload("res://content/sounds/Weapons/obelisk/upgrade_open.wav")
var close_upgrades = preload("res://content/sounds/Weapons/obelisk/upgrade_close.wav")

var loadout_keeper1 = preload("res://content/sounds/UI/Keeper1Selection.wav")
var loadout_keeper2 = preload("res://content/sounds/UI/Keeper2Selection.wav")
var loadout_dome1 = preload("res://content/sounds/UI/SelectLaser_v2.wav")
var loadout_dome2 = preload("res://content/sounds/UI/SelectSword.wav")
var loadout_orchard = preload("res://content/sounds/UI/SelectOrchard.wav")
var loadout_shield = preload("res://content/sounds/UI/SelectShield.wav")
var loadout_repellent = preload("res://content/sounds/UI/SelectRepellent.wav")
var loadout_prestige = preload("res://content/sounds/UI/SelectPrestige.wav")
var loadout_relichunt = preload("res://content/sounds/UI/SelectRelicHunt.wav")
var loadout_pet = preload("res://content/sounds/UI/PetSelection.wav")
var loadout_skin = preload("res://content/sounds/UI/Keeperstyleselect.wav")
var loadout_modebasic = preload("res://content/sounds/UI/Mode_basic.wav")
var loadout_modecobolt = preload("res://content/sounds/UI/Mode_cobolt.wav")
var loadout_modetimed = preload("res://content/sounds/UI/Mode_Time.wav")
var loadout_modeminer = preload("res://content/sounds/UI/Mode_Time.wav")
var gui_loadout_startrun = preload("res://content/sounds/UI/StartRun.wav")

var alarm = preload("res://content/sounds/UI/Alarm.wav")
var wavestart = preload("res://content/sounds/UI/GongRiser.wav")
var wavedread = preload("res://content/sounds/UI/wave_Cave_amb.wav")
var gadgetinsert = preload("res://content/sounds/Locations/RelicRoom/GadgetInsert.wav")
var cobaltscavenge = preload("res://content/sounds/drops/Metaltest_03.wav")
var apple = preload("res://content/sounds/Locations/Orchard/Eat_apple_01.wav")
var appleupgrade1 = preload("res://content/sounds/Locations/Orchard/Eat_apple_02.wav")
var appleupgrade2 = preload("res://content/sounds/Locations/Orchard/Eat_apple_03.wav")
var appleupgrade3 = preload("res://content/sounds/Locations/Orchard/Eat_apple_04.wav")
var lose = preload("res://content/sounds/UI/Defeat.wav")
var unlock_event = preload("res://content/sounds/Bastards/Achiemenet.wav")

var m_mining_keeper1 = [
	preload("res://content/music/ENGINEER Between the Waves.ogg"), 
	preload("res://content/music/ENGINEER Delving.ogg"), 
	preload("res://content/music/ENGINEER Lost in the Mines.ogg"), 
	preload("res://content/music/ENGINEER A Moment to Breathe.ogg"), 
	preload("res://content/music/ENGINEER Deeper and Deeper.ogg"), 
	preload("res://content/music/ENGINEER Further Underneath.ogg"), 
	preload("res://content/music/ENGINEER The Engineer.ogg"), 
	preload("res://content/music/ENGINEER Ancient Artifact.ogg"), 
	preload("res://content/music/ENGINEER Undiscovered Flora.ogg"), 
	preload("res://content/music/ENGINEER_Ode_to_Iron.ogg"), 
	]

var m_mining_keeper2 = [
	preload("res://content/music/ASSESSOR Alchemy.ogg"), 
	preload("res://content/music/ASSESSOR Caves Beyond.ogg"), 
	preload("res://content/music/ASSESSOR Claustrophobe.ogg"), 
	preload("res://content/music/ASSESSOR Eternal Dust.ogg"), 
	preload("res://content/music/ASSESSOR Layer By Layer.ogg"), 
	preload("res://content/music/ASSESSOR Lonely Job.ogg"), 
	preload("res://content/music/ASSESSOR Sombre.ogg"), 
	preload("res://content/music/ASSESSOR The Very Last Egg.ogg"), 
	preload("res://content/music/ASSESSOR Vestigial Eye.ogg"), 
	preload("res://content/music/ASSESSOR The Assessor.ogg"), 
]

var m_battle = [preload("res://content/music/BATTLE LASER.ogg")]

var m_intro_keeper1: = preload("res://content/music/ENGINEER Dome Keeper [intro].ogg")
var m_intro_loop_keeper1: = preload("res://content/music/ENGINEER Dome Keeper [loop].ogg")
var m_intro_keeper2: = preload("res://content/music/ASSESSOR Dome Keeper [intro].ogg")
var m_intro_loop_keeper2: = preload("res://content/music/ASSESSOR Dome Keeper [loop].ogg")

var m_ending_keeper1: = preload("res://content/music/ENGINEER Laser Party [intro].ogg")
var m_ending_loop_keeper1: = preload("res://content/music/ENGINEER Laser Party [loop].ogg")
var m_ending_keeper2: = preload("res://content/music/ASSESSOR The Perfect Bounce [intro].ogg")
var m_ending_loop_keeper2: = preload("res://content/music/ASSESSOR The Perfect Bounce [loop].ogg")

var m_game_over_keeper1: = preload("res://content/music/ENGINEER Collapse [intro].ogg")
var m_game_over_loop_keeper1: = preload("res://content/music/ENGINEER Collapse [loop].ogg")
var m_game_over_keeper2: = preload("res://content/music/ASSESSOR All Too Familiar [intro].ogg")
var m_game_over_loop_keeper2: = preload("res://content/music/ASSESSOR All Too Familiar [loop].ogg")

var pitchStream: = AudioStreamRandomPitch.new()

var soundPlayers: = []

var autoVolumeBattleMusic: = false
var ignoreHover: = false
var currentMineAmbience: AudioStreamPlayer

var musicBaseAmplification: float

func _ready():




	for i in range(0, 8):
		var p = AudioStreamPlayer.new()
		p.bus = BUS_UI
		soundPlayers.append(p)
		add_child(p)
		p.connect("finished", self, "soundPlayerFinished", [i])
	get_viewport().connect("gui_focus_changed", self, "playUiHoverSound")
	
	var amplify: AudioEffectAmplify = AudioServer.get_bus_effect(AudioServer.get_bus_index(Audio.BUS_MUSIC), 0)
	musicBaseAmplification = amplify.volume_db

func ignoreNextHover():
	ignoreHover = true

func playUiHoverSound(v):
	if ignoreHover:
		ignoreHover = false
		return 
	Audio.sound("gui_hover")

func _process(delta):
	
	if Level.dome and Level.world:
		if GameWorld.won or GameWorld.lost:
			stopAmbienceMine()
			Level.dome.ambience().stop()
			Level.world.ambience().stop()
		elif Data.of("keeper.insidedome"):
			if InputSystem.getCamera().zoom.x > 0.33:
				Level.dome.ambience().stop()
				Level.world.ambience().start()
				stopAmbienceMine()
			else:
				Level.dome.ambience().start()
				Level.world.ambience().stop()
				stopAmbienceMine()
		else:
			Level.dome.ambience().stop()
			Level.world.ambience().stop()
			playAmbienceMine()
	else:
		stopAmbienceMine()
	
	if Level.keeper and autoVolumeBattleMusic:
		var diff = (Level.dome.cellarEntranceY() - Level.keeper.position.y) * 0.2
		$BattleMusic.volume_db = clamp(diff, - 60, - 6)

func playAmbienceMine():
	var coord = Level.map.getTileCoord(Level.keeper.global_position)
	var biome: String = Level.map.getBiomeOfCoord(coord)
	var biomeAmbience = find_node("AmbienceMine" + biome.capitalize())
	if currentMineAmbience and currentMineAmbience != biomeAmbience:
		currentMineAmbience.stop()
		currentMineAmbience = null
	
	if not currentMineAmbience and biomeAmbience:
		var layer: int = Level.map.getLayerOfCoord(coord)
		biomeAmbience.pitch_scale = 1.0 - layer * 0.02
		currentMineAmbience = biomeAmbience
		currentMineAmbience.start()

func stopAmbienceMine():
	if currentMineAmbience:
		currentMineAmbience.stop()
		currentMineAmbience = null

func playRandomPitch(soundName: String):
	var sounds = get(soundName)
	if sounds:
		var p = getAudioStream()
		p.stream = pitchStream
		p.stream.set_audio_stream(sounds[randi() % sounds.size()])
		p.play()
	else:
		print("Sound \"" + soundName + "\" is not defined")

func sound(soundName: String):


	var s = get(soundName)
	if s:
		var p = getAudioStream()
		p.stream = s
		p.play()
	else:
		print("Sound \"" + soundName + "\" is not defined")

func stinger(soundName: String):
	var s = get(soundName)
	if s:
		$Stinger.stream = s
		var amplify: AudioEffectAmplify = AudioServer.get_bus_effect(AudioServer.get_bus_index(Audio.BUS_MUSIC), 0)
		$StingerTween.interpolate_callback($Stinger, 0.15, "play")
		$StingerTween.interpolate_property(amplify, "volume_db", amplify.volume_db, musicBaseAmplification - 42, 0.25)
		$StingerTween.start()
	else:
		print("Sound \"" + soundName + "\" is not defined")

func getAudioStream()->AudioStreamPlayer:
	
	for p in soundPlayers:
			if not p.playing:
				return p
	
	if soundPlayers.size() < 20:
		var p = AudioStreamPlayer.new()
		p.bus = BUS_UI
		soundPlayers.append(p)
		add_child(p)
		return p
	
	return soundPlayers.front()

func playRandomDelay(soundName: String, delay: float):
	$SoundTween.interpolate_callback(self, delay, "sound", soundName)
	$SoundTween.start()

func playSound(soundName: String):
	var sound = get(soundName)
	if sound:
		stream = sound
		play()
	else:
		print("Sound \"" + soundName + "\" is not defined")

func playPitched(soundName: String, pitch: float):
	var sound = get(soundName)
	if sound:
		stream = sound
		pitch_scale = pitch
		play()
	else:
		print("Sound \"" + soundName + "\" is not defined")

func playSoundIndex(soundName: String, index: int):
	var sounds = get(soundName)
	if sounds:
		stream = sounds[index]
		play()
	else:
		print("Sound \"" + soundName + "\" is not defined")

func playSoundDelay(soundName: String, delay: float):
	$SoundTween.interpolate_callback(self, delay, "playSound", soundName)
	$SoundTween.start()

func getRandomSound(soundName: String):
	var sound = get(soundName)
	if sound and sound is Array:
		return sound[randi() % sound.size()]
	else:
		print("Sound \"" + soundName + "\" is not defined or not an Array")

func startMusic(i: int, delay: = 0.0):
	$Music.stop()
	var miningMusic = get("m_mining_" + GameWorld.lastKeeperId)
	if not miningMusic:
		Logger.error("no music found for keeper", "Audio.startMusic", "m_mining_" + GameWorld.lastKeeperId)
		return 
	$Music.stream = miningMusic[i % miningMusic.size()]
	$Music.volume_db = 0
	$MusicTween.stop_all()
	$MusicTween.remove_all()
	$MusicTween.interpolate_callback($Music, delay, "play")
	$MusicTween.start()

func stopMusic(delay: = 0.0, fade: = 6.0):
	$MusicTween.stop_all()
	$MusicTween.remove_all()
	$MusicTween.interpolate_property($Music, "volume_db", $Music.volume_db, - 60, fade, Tween.TRANS_LINEAR, Tween.EASE_IN, delay)
	$MusicTween.interpolate_callback($Music, fade + delay, "stop")
	$MusicTween.start()

func isMusicPlaying()->bool:
	return $Music.playing and $Music.volume_db > - 40

func startBattleMusic():
	$BattleTween.stop_all()
	$BattleTween.remove_all()
	$BattleMusic.stop()





func stopBattleMusic():
	if not $BattleMusic.playing:
		return 
	
	$BattleTween.stop_all()
	$BattleTween.remove_all()
	$BattleTween.interpolate_property($BattleMusic, "volume_db", $BattleMusic.volume_db, - 60, 6.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$BattleTween.interpolate_callback($BattleMusic, 6.0, "stop")
	$BattleTween.start()
	autoVolumeBattleMusic = false

func startIntro():
	if $Music.stream == get("m_intro_" + GameWorld.lastKeeperId) and $Music.playing:
		return 
	
	$Music.stop()
	$MusicTween.stop_all()
	$MusicTween.remove_all()
	$Music.stream = get("m_intro_" + GameWorld.lastKeeperId)
	$Music.volume_db = 0
	$Music.play(0.0)

func startEnding(delay: = 0.0):
	if $Music.playing:
		delay += 1.0
	
	if delay > 0.0:
		$MusicTween.stop_all()
		$MusicTween.remove_all()
		$MusicTween.interpolate_property($Music, "volume_db", $Music.volume_db, - 60, delay * 0.9, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$MusicTween.interpolate_callback($Music, delay * 0.9, "stop")
		$MusicTween.interpolate_callback(self, delay, "startEnding")
		$MusicTween.start()
		return 
	$MusicTween.stop_all()
	$MusicTween.remove_all()
	$Music.stream = get("m_ending_" + GameWorld.lastKeeperId)
	$Music.volume_db = 0
	$Music.play()

func startGameOver(delay: = 0.0):
	if $Music.playing:
		delay += 1.0
	
	if delay > 0.0:
		$MusicTween.stop_all()
		$MusicTween.remove_all()
		$MusicTween.interpolate_property($Music, "volume_db", $Music.volume_db, - 60, delay * 0.9, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$MusicTween.interpolate_callback($Music, delay * 0.9, "stop")
		$MusicTween.interpolate_callback(self, delay, "startGameOver")
		$MusicTween.start()
		return 
	$MusicTween.stop_all()
	$MusicTween.remove_all()
	$Music.stream = get("m_game_over_" + GameWorld.lastKeeperId)
	$Music.volume_db = 0
	$Music.play()

func _on_Music_finished()->void :
	if $Music.stream == get("m_intro_" + GameWorld.lastKeeperId):
		$Music.stream = get("m_intro_loop_" + GameWorld.lastKeeperId)
		$Music.play()
	elif $Music.stream == get("m_ending_" + GameWorld.lastKeeperId):
		$Music.stream = get("m_ending_loop_" + GameWorld.lastKeeperId)
		$Music.play()
	elif $Music.stream == get("m_game_over_" + GameWorld.lastKeeperId):
		$Music.stream = get("m_game_over_loop_" + GameWorld.lastKeeperId)
		$Music.play()

func soundPlayerFinished(i)->void :
	soundPlayers[i].stop()

func get_bus_volume(busname: String)->float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(busname))

func set_bus_volume(busname: String, volume: float):
	return AudioServer.set_bus_volume_db(AudioServer.get_bus_index(busname), volume)

func muteSounds():
	var busIdx = AudioServer.get_bus_index(BUS_SOUNDS)
	var amplify: AudioEffectAmplify = AudioServer.get_bus_effect(busIdx, 0)
	$MuteSoundTween.remove_all()
	$MuteSoundTween.interpolate_property(amplify, "volume_db", amplify.volume_db, - 60, 0.3)
	$MuteSoundTween.start()

func unmuteSounds():
	var busIdx = AudioServer.get_bus_index(BUS_SOUNDS)
	var amplify: AudioEffectAmplify = AudioServer.get_bus_effect(busIdx, 0)
	$MuteSoundTween.remove_all()
	$MuteSoundTween.interpolate_property(amplify, "volume_db", amplify.volume_db, 0, 0.3)
	$MuteSoundTween.start()

func _on_Stinger_finished():
	var amplify: AudioEffectAmplify = AudioServer.get_bus_effect(AudioServer.get_bus_index(Audio.BUS_MUSIC), 0)
	$StingerTween.interpolate_property(amplify, "volume_db", amplify.volume_db, musicBaseAmplification, 2.0)
	$StingerTween.start()
