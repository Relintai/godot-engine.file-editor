tool
extends Control

onready var FileList = $FileList

onready var NewFileDialogue = $NewFileDialogue
onready var NewFileDialogue_name = $NewFileDialogue/VBoxContainer/new_filename

onready var FileBTN = $FileEditorContainer/TobBar/file_btn.get_popup()
onready var PreviewBTN = $FileEditorContainer/TobBar/preview_btn.get_popup()
onready var SettingsBTN : PopupMenu = $FileEditorContainer/TobBar/SettingsBtn.get_popup()

onready var SelectFontDialog : FileDialog = $SelectFontDialog

onready var FileContainer = $FileEditorContainer/SplitContainer/FileContainer
onready var OpenFileList = $FileEditorContainer/SplitContainer/FileContainer/OpenFileList
onready var OpenFileName = $FileEditorContainer/SplitContainer/EditorContainer/HBoxContainer/OpenFileName
onready var SplitEditorContainer = $FileEditorContainer/SplitContainer/EditorContainer
onready var WrapBTN = $FileEditorContainer/SplitContainer/EditorContainer/HBoxContainer/wrap_button
onready var MapBTN = $FileEditorContainer/SplitContainer/EditorContainer/HBoxContainer/map_button

onready var ConfirmationClose = $ConfirmationDialog

var IconLoader = preload("res://addons/file-editor/scripts/IconLoader.gd").new()
var LastOpenedFiles = preload("res://addons/file-editor/scripts/LastOpenedFiles.gd").new()

var Preview = preload("res://addons/file-editor/scripts/Preview.gd")
var VanillaEditor = preload("res://addons/file-editor/scripts/VanillaEditor.gd")

onready var EditorContainer = $FileEditorContainer/SplitContainer

var DIRECTORY : String = "res://"
var EXCEPTIONS : String = "addons"
var EXTENSIONS : PoolStringArray = [
"*.txt ; Plain Text File",
"*.rtf ; Rich Text Format File",
"*.log ; Log File",
"*.md ; MD File",
"*.doc ; WordPad Document",
"*.doc ; Microsoft Word Document",
"*.docm ; Word Open XML Macro-Enabled Document",
"*.docx ; Microsoft Word Open XML Document",
"*.bbs ; Bulletin Board System Text",
"*.dat ; Data File",
"*.xml ; XML File",
"*.sql ; SQL database file",
"*.json ; JavaScript Object Notation File",
"*.html ; HyperText Markup Language",
"*.csv ; Comma-separated values",
"*.cfg ; Configuration File",
"*.ini ; Initialization File (same as .cfg Configuration File)",
"*.csv ; Comma-separated values File",
"*.res ; Resource File",
]

var directories = []
var files = []
var current_file_index = -1
var current_file_path = ""
var save_as = false
var current_editor : Control
var current_font : DynamicFont

var editing_file : bool = false

func _ready():
	if not Engine.is_editor_hint():
		return
		
	clean_editor()
	connect_signals()
	create_shortcuts()
	load_icons()
	
	var opened_files : Array = LastOpenedFiles.load_opened_files()
	for opened_file in opened_files:
		open_file(opened_file[1], opened_file[2])
		
	FileList.set_filters(EXTENSIONS)

func create_shortcuts():
	var hotkey

	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_S
	hotkey.control = true
	FileBTN.set_item_accelerator(4,hotkey.get_scancode_with_modifiers()) # save file

	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_N
	hotkey.control = true
	FileBTN.set_item_accelerator(0,hotkey.get_scancode_with_modifiers()) # new file

	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_O
	hotkey.control = true
	FileBTN.set_item_accelerator(1,hotkey.get_scancode_with_modifiers()) # open file

	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_D
	hotkey.control = true
	FileBTN.set_item_accelerator(6,hotkey.get_scancode_with_modifiers()) # delete file

	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_S
	hotkey.control = true
	hotkey.alt = true
	FileBTN.set_item_accelerator(5,hotkey.get_scancode_with_modifiers()) #save file as

	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_C
	hotkey.control = true
	hotkey.alt = true
	FileBTN.set_item_accelerator(2,hotkey.get_scancode_with_modifiers()) # close file

	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_F
	hotkey.control = true
	FileBTN.set_item_accelerator(8,hotkey.get_scancode_with_modifiers()) # search

	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_R
	hotkey.control = true
	FileBTN.set_item_accelerator(9,hotkey.get_scancode_with_modifiers()) # replace


func load_icons():
	$FileEditorContainer/TobBar/file_btn.icon = IconLoader.load_icon_from_name("file")
	$FileEditorContainer/TobBar/preview_btn.icon = IconLoader.load_icon_from_name("read")
	$FileEditorContainer/TobBar/SettingsBtn.icon = IconLoader.load_icon_from_name("settings")

func connect_signals():
	FileList.connect("confirmed",self,"update_list")
	FileBTN.connect("id_pressed",self,"_on_filebtn_pressed")
	PreviewBTN.connect("id_pressed",self,"_on_previewbtn_pressed")
	SettingsBTN.connect("id_pressed",self,"_on_settingsbtn_pressed")
	
	OpenFileList.connect("item_selected",self,"_on_fileitem_pressed")
	WrapBTN.connect("item_selected",self,"on_wrap_button")
	MapBTN.connect("item_selected",self,"on_minimap_button")
	
	SelectFontDialog.connect("file_selected",self,"_on_font_selected")


func create_selected_file():
		update_list()
		
		FileList.mode = FileDialog.MODE_SAVE_FILE
		FileList.set_title("Create a new File")
		
		if FileList.is_connected("file_selected",self,"delete_file"):
				FileList.disconnect("file_selected",self,"delete_file")
				
		if FileList.is_connected("file_selected",self,"open_file"):
				FileList.disconnect("file_selected",self,"open_file")
				
		if not FileList.is_connected("file_selected",self,"create_new_file"):
				FileList.connect("file_selected",self,"create_new_file")
				
		open_filelist()

func open_selected_file():
		update_list()
		
		FileList.mode = FileDialog.MODE_OPEN_FILE
		FileList.set_title("Select a File you want to edit")
		
		if FileList.is_connected("file_selected",self,"delete_file"):
				FileList.disconnect("file_selected",self,"delete_file")
				
		if FileList.is_connected("file_selected",self,"create_new_file"):
				FileList.disconnect("file_selected",self,"create_new_file")
				
		if not FileList.is_connected("file_selected",self,"open_file"):
				FileList.connect("file_selected",self,"open_file")
				
		open_filelist()

func delete_selected_file():
		update_list()
		
		FileList.mode = FileDialog.MODE_OPEN_FILES
		FileList.set_title("Select one or more Files you want to delete")
		
		if FileList.is_connected("file_selected",self,"open_file"):
				FileList.disconnect("file_selected",self,"open_file")
				
		if FileList.is_connected("file_selected",self,"create_new_file"):
				FileList.disconnect("file_selected",self,"create_new_file")
				
		if not FileList.is_connected("files_selected",self,"delete_file"):
				FileList.connect("files_selected",self,"delete_file")
				
		open_filelist()

func save_current_file_as():
		update_list()
		FileList.mode = FileDialog.MODE_SAVE_FILE
		FileList.set_title("Save this File as...")
		
		if FileList.is_connected("file_selected",self,"delete_file"):
				FileList.disconnect("file_selected",self,"delete_file")
				
		if FileList.is_connected("file_selected",self,"open_file"):
				FileList.disconnect("file_selected",self,"open_file")
				
		if not FileList.is_connected("file_selected",self,"create_new_file"):
				FileList.connect("file_selected",self,"create_new_file")
				
		open_filelist()

func _on_filebtn_pressed(index : int):
		match index:
				0:
						create_selected_file()
				1:
						open_selected_file()
				2:
						if current_file_index!=-1 and current_file_path != "":
								close_file(current_file_index)
				
				3:
						if current_file_index!=-1 and current_file_path != "":
								save_as = false

								save_file(current_file_path)
				4:
						if current_file_index!=-1 and current_file_path != "":
								save_as = true
								save_file(current_file_path)
								save_current_file_as()
				5:
						delete_selected_file()
				6:
						current_editor.open_searchbox()
				7:
						current_editor.open_replacebox()

func _on_previewbtn_pressed(id : int):
		if id == 0:
				bbcode_preview()
		elif id == 1:
				markdown_preview()
		elif id == 2:
				html_preview()
		elif id == 3:
				csv_preview()

func _on_settingsbtn_pressed(index : int):
	match index:
		0:
			SelectFontDialog.popup()

func _on_font_selected(font_path : String):
	current_editor.set_font(font_path)
	LastOpenedFiles.store_editor_fonts(current_file_path.get_file(), font_path)

func _on_fileitem_pressed(index : int):
	current_file_index = index
	var selected_item_metadata = OpenFileList.get_item_metadata(current_file_index)
	var extension = selected_item_metadata[0].current_path.get_file().get_extension()
	
	if OpenFileList.get_item_text(current_file_index).begins_with("(*)"):
		editing_file = true
	else:
		editing_file = false
		
	current_file_path = selected_item_metadata[0].current_path
	
	if current_editor.visible or current_editor == null:
		if current_editor != null:
			current_editor.hide()
		
		current_editor = selected_item_metadata[0]
		current_editor.show()
		OpenFileName.set_text(current_editor.current_path)

		if WrapBTN.get_selected_id() == 1:
			current_editor.set_wrap_enabled(true)
		else:
			current_editor.set_wrap_enabled(false)
			
		if MapBTN.get_selected_id() == 1:
			current_editor.draw_minimap(true)
		else:
			current_editor.draw_minimap(false)

func open_file(path : String, font : String = "null"):
	if current_file_path != path:
		current_file_path = path
		
		var vanilla_editor = open_in_vanillaeditor(path)
		
		if font != "null" and vanilla_editor.get("custom_fonts/font")!=null:
			vanilla_editor.set_font(font)

		generate_file_item(path, vanilla_editor)
		
		LastOpenedFiles.store_opened_files(OpenFileList)
		
	current_editor.show()

func generate_file_item(path : String , veditor : Control):
	OpenFileName.set_text(path)
	OpenFileList.add_item(path.get_file(),IconLoader.load_icon_from_name("file"),true)
	
	current_file_index = OpenFileList.get_item_count()-1
	
	OpenFileList.set_item_metadata(current_file_index,[veditor])
	OpenFileList.select(OpenFileList.get_item_count()-1)

func open_in_vanillaeditor(path : String) -> Control:
	var editor = VanillaEditor.new()
	SplitEditorContainer.add_child(editor,true)
	
	if current_editor and current_editor!=editor:
		editor.show()
		current_editor.hide()
		
	
	current_editor = editor
	editor.connect("text_changed",self,"_on_vanillaeditor_text_changed")
	
	var current_file : File = File.new()
	current_file.open(path,File.READ)
	var current_content = ""
	current_content = current_file.get_as_text()
	
	var last_modified = OS.get_datetime_from_unix_time(current_file.get_modified_time(path))
	
	current_file.close()
	editor.new_file_open(current_content,last_modified,current_file_path)
	update_list()
	
	if WrapBTN.get_selected_id() == 1:
		current_editor.set_wrap_enabled(true)
	
	return editor

func close_file(index):
	if editing_file:
		ConfirmationClose.popup()
	else:
		confirm_close(index)

func confirm_close(index):
	LastOpenedFiles.remove_opened_file(index,OpenFileList)
	OpenFileList.remove_item(index)
	OpenFileName.clear()
	current_editor.queue_free()
	
	if index > 0:
		OpenFileList.select(index-1)
		_on_fileitem_pressed(index-1)

func _on_update_file():
	var current_file : File = File.new()
	current_file.open(current_file_path,File.READ)
	
	var current_content = current_file.get_as_text()
	var last_modified = OS.get_datetime_from_unix_time(current_file.get_modified_time(current_file_path))
	
	current_file.close()
	
	current_editor.new_file_open(current_content,last_modified,current_file_path)

func delete_file(files_selected : PoolStringArray):
	var dir = Directory.new()
	for file in files_selected:
		dir.remove(file)
	
	update_list()

func open_newfiledialogue():
	NewFileDialogue.popup()
	NewFileDialogue.set_position(OS.get_screen_size()/2 - NewFileDialogue.get_size()/2)

func open_filelist():
	update_list()
	FileList.popup()
	FileList.set_position(OS.get_screen_size()/2 - FileList.get_size()/2)

func create_new_file(given_path : String):
	var current_file = File.new()
	current_file.open(given_path,File.WRITE)
	if save_as : 
			current_file.store_line(current_editor.text_editor.get_text())
	current_file.close()
	
	open_file(given_path)

func save_file(current_path : String):
	print("Saving file: ",current_path)
	var current_file = File.new()
	current_file.open(current_path,File.WRITE)
	var current_content = ""
	var lines = current_editor.text_editor.get_line_count()
	
	for line in range(0,lines):
		if current_editor.text_editor.get_line(line) == "":
			continue
			
		current_content = current_editor.text_editor.get_text()
		current_file.store_line(current_editor.text_editor.get_line(line))
		
	current_file.close()
	
	current_file_path = current_path
	
	var last_modified = OS.get_datetime_from_unix_time(current_file.get_modified_time(current_file_path))
	
	current_editor.update_lastmodified(last_modified,"save")
	
		
	OpenFileList.set_item_metadata(current_file_index,[current_editor])
	
	if OpenFileList.get_item_text(current_file_index).begins_with("(*)"):
		OpenFileList.set_item_text(current_file_index,OpenFileList.get_item_text(current_file_index).lstrip("(*)"))
		editing_file = false
	
	update_list()

func clean_editor() -> void :
	for vanillaeditor in get_tree().get_nodes_in_group("vanilla_editor"):
		vanillaeditor.queue_free()
		
	OpenFileName.clear()
	OpenFileList.clear()


func csv_preview():
	var preview = Preview.new()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_file_path.get_file()+")"
	var lines = current_editor.text_editor.get_line_count()
	var rows = []
	
	for i in range(0,lines-1):
		rows.append(current_editor.text_editor.get_line(i).rsplit(",",false))
		
	preview.print_csv(rows)

func bbcode_preview():
	var preview = Preview.new()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_file_path.get_file()+")"
	preview.print_bb(current_editor.text_editor.get_text())

func markdown_preview():
	var preview = Preview.new()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_file_path.get_file()+")"
	preview.print_markdown(current_editor.text_editor.get_text())

func html_preview():
	var preview = Preview.new()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_file_path.get_file()+")"
	preview.print_html(current_editor.text_editor.get_text())


func _on_vanillaeditor_text_changed():
	if not OpenFileList.get_item_text(current_file_index).begins_with("(*)"):
		OpenFileList.set_item_text(current_file_index,"(*)"+OpenFileList.get_item_text(current_file_index))
		editing_file = true

func update_list():
		FileList.invalidate()

func on_wrap_button(index:int):
	match index:
		0:
			current_editor.set_wrap_enabled(false)
		1:
			current_editor.set_wrap_enabled(true)

func on_minimap_button(index:int):
	match index:
		0:
			current_editor.draw_minimap(false)
		1:
			current_editor.draw_minimap(true)

func check_file_preview(file : String):
	# check whether the opened file has a corresponding preview session for its extension
		pass


func _on_ConfirmationDialog_confirmed():
	confirm_close(current_file_index)
