extends PanelContainer

signal received_list
signal received_entry
signal entry_selected

var page: = 0
var pageSize: = 50
var maxPage: = 0
var directory: = ""
var pattern: = ""
var listingEntry: = ""
var listingData: Dictionary

var currentGetUrl

func start(title, directory, pattern: = ""):
	var dir = Directory.new()
	dir.open("user://")
	dir.make_dir("cache")
	
	self.directory = directory
	self.pattern = pattern
	listingData = {}
	find_node("ListingLabel").text = title
	find_node("PaginationLabel").text = ""
	find_node("NextListing").disabled = true
	find_node("PreviousListing").disabled = true
	clearListing()
	$GetListing.do(directory, page, pageSize, pattern)
	$GetNumberOfListingEntries.do(directory, pattern)

func entrySelected(n, url):
	listingEntry = n
	currentGetUrl = url
	$GetFile.cancel_request()
	var f = File.new()
	var err = f.open("user://cache/" + currentGetUrl.substr(currentGetUrl.find_last("/") + 1), File.READ)
	if err == 0:
		call_deferred("emit_signal", "received_entry", f.get_as_text())
	else:
		$GetFile.do(url)
	f.close()
	emit_signal("entry_selected")

func registerEntries(entries):
	listingData[listingEntry] = entries

func getData(n = listingEntry):
	return listingData.get(n, null)

func _on_NextListing_pressed():
	Audio.sound("gui_select")
	clearListing()
	page += 1
	$GetListing.do(directory, page, pageSize, pattern)

func _on_PreviousListing_pressed():
	Audio.sound("gui_select")
	clearListing()
	page -= 1
	$GetListing.do(directory, page, pageSize, pattern)

func clearListing():
	for c in find_node("ListingContent").get_children():
		find_node("ListingContent").remove_child(c)
		c.queue_free()

func updatePagination():
	find_node("PreviousListing").disabled = page == 0
	find_node("NextListing").disabled = page + 1 >= maxPage
	find_node("PaginationLabel").text = str(page + 1) + " of " + str(maxPage)

func _on_GetNumberOfListingEntries_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		Logger.error(str(response_code), "_on_GetNumberOfListingEntries_request_completed", body.get_string_from_utf8())
		return 
	var count = int(body.get_string_from_utf8())
	print("NumberOfListingEntries = " + str(count))
	maxPage = ceil(float(count) / pageSize)
	updatePagination()

func _on_GetListing_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		Logger.error(str(response_code), "_on_GetListing_request_completed", body.get_string_from_utf8())
		return 
	
	var data = JSON.parse(body.get_string_from_utf8()).result
	print("Received " + str(data.size()) + " ListingEntries.")
	var group = ButtonGroup.new()
	for d in data:
		var b: = Button.new()
		b.set("custom_fonts/font", preload("res://gui/fonts/FontSmall.tres"))
		b.focus_mode = Button.FOCUS_NONE
		
		var n = d["name"].substr(0, d["name"].find("-") + 4)
		n = n.substr(0, n.find_last("_"))
		b.text = n
		b.group = group
		b.toggle_mode = true
		b.connect("pressed", self, "entrySelected", [n, d.get("publicUrl")])
		find_node("ListingContent").add_child(b)
		Style.init(b)
	updatePagination()

func displayCachedSessions(sessionFiles: Array):
	var LC = find_node("ListingContent")
	for c in LC.get_children():
		LC.remove_child(c)
	
	var group = ButtonGroup.new()
	for d in sessionFiles:
		var b: = Button.new()
		b.set("custom_fonts/font", preload("res://gui/fonts/FontSmall.tres"))
		var n = d.substr(0, d.find("-"))
		b.text = n
		b.group = group
		b.toggle_mode = true
		b.connect("pressed", self, "showEntry", [d])
		LC.add_child(b)
		Style.init(b)
	
	if LC.get_child_count() > 0:
		LC.get_child(0).pressed = true
		LC.get_child(0).emit_signal("pressed")
	
	find_node("PaginationLabel").text = str(sessionFiles.size()) + " sessions"
	find_node("PreviousListing").visible = false
	find_node("NextListing").visible = false

func showEntry(file):
	var f = File.new()
	var err = f.open("user://cache/" + file, File.READ)
	if err == 0:
		call_deferred("emit_signal", "received_entry", f.get_as_text())
	f.close()
	emit_signal("entry_selected")

func _process(delta: float)->void :
	var LC = find_node("ListingContent")
	var index: = - 1
	for c in LC.get_children():
		if c.pressed:
			index = c.get_index()
			break
	
	if index == - 1:
		return 
	
	if Input.is_action_just_pressed("ui_up") and index > 0:
		LC.get_child(index - 1).pressed = true
		LC.get_child(index - 1).emit_signal("pressed")
		InputSystem.grabFocus(LC.get_child(index - 1))
	if Input.is_action_just_pressed("ui_down") and index < LC.get_child_count() - 1:
		LC.get_child(index + 1).pressed = true
		LC.get_child(index + 1).emit_signal("pressed")
		InputSystem.grabFocus(LC.get_child(index + 1))

func _on_GetFile_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		Logger.error(str(response_code), "_on_GetFile_request_completed", body.get_string_from_utf8())
		return 
	var f = File.new()
	var err = f.open("user://cache/" + currentGetUrl.substr(currentGetUrl.find_last("/") + 1), File.WRITE)
	if err == 0:
		f.store_string(body.get_string_from_utf8())
	else:
		Logger.error("_on_GetFile_request_completed", "WriteFail" + str(err))
	f.close()
	
	emit_signal("received_entry", body.get_string_from_utf8())

func gotListing(d1, d2):
	emit_signal("received_list", d1, d2)
