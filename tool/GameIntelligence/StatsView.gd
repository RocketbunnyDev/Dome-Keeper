extends PanelContainer

onready var StatEntry = find_node("StatEntry")

func updateStats(filteredRuns: Array, filter: Dictionary):
	visible = true
	StatEntry.updateStats(filteredRuns, filter)

func _on_StatEntry_pin(filteredRuns, filter):
	var entry = preload("res://tool/GameIntelligence/StatEntry.tscn").instance()
	entry.find_node("PinStatsButton").visible = false
	entry.find_node("DeleteStatsButton").visible = true

	var container = PanelContainer.new()
	entry.updateStats(filteredRuns, filter)
	container.add_child(entry)
	find_node("AllEntriesContainer").add_child(container)
	
	Style.init(container)
