extends Node

func _on_Layer1_finished()->void :
	$Layer1.stream = preload("res://content/music/[2021-09-01] Enemy Wave Layer 1 Basic [Loop] MASTER.ogg")

func start():
	$Layer1.volume_db = 0
	$Layer1.stream = preload("res://content/music/[2021-09-01] Dome Romantik Title Screen [Intro] MASTER.ogg")
	$Layer1.play()
	$Layer2.volume_db = - 60
	$Layer3.volume_db = - 60
	$Layer4.volume_db = - 60
	$Layer5.volume_db = - 60
