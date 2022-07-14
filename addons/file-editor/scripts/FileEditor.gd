tool
extends Control

enum FileMenuOptions {
	FILE_MENU_OPTION_NEW = 0,
	FILE_MENU_OPTION_OPEN = 1,
	FILE_MENU_OPTION_CLOSE = 2,
	FILE_MENU_OPTION_SAVE = 3,
	FILE_MENU_OPTION_SAVE_AS = 4,
	FILE_MENU_OPTION_DELETE = 5,
	FILE_MENU_OPTION_SEARCH = 6,
	FILE_MENU_OPTION_REPLACE = 7,
};

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


var file_btn : MenuButton = null
var preview_btn : MenuButton = null
var settings_btn : MenuButton = null

var file_btn_popup : PopupMenu = null
var preview_btn_popup : PopupMenu = null
var settings_btn_popup : PopupMenu = null

var editor_container : HSplitContainer = null
var file_container : VBoxContainer = null
var open_file_list : ItemList = null
var split_editor_container : VBoxContainer = null
var open_file_name : LineEdit = null
var wrap_btn : OptionButton = null
var map_btn : OptionButton = null

var file_list : FileDialog = null

var new_file_dialogue : AcceptDialog = null
var new_file_dialogue_name : LineEdit = null

var confirmation_close : ConfirmationDialog = null

var select_font_dialog : FileDialog = null

var IconLoader = preload("res://addons/file-editor/scripts/IconLoader.gd").new()
var LastOpenedFiles = preload("res://addons/file-editor/scripts/LastOpenedFiles.gd").new()

var Preview = preload("res://addons/file-editor/scripts/Preview.gd")
var VanillaEditor = preload("res://addons/file-editor/scripts/VanillaEditor.gd")

var directories = []
var files = []
var current_file_index = -1
var current_file_path = ""
var save_as = false
var current_editor : Control
var current_font : DynamicFont

var editing_file : bool = false

func _init():
	set_anchors_and_margins_preset(Control.PRESET_WIDE)
	size_flags_vertical = SIZE_EXPAND_FILL
	size_flags_horizontal = SIZE_EXPAND_FILL
	
	var vbc : VBoxContainer = VBoxContainer.new()
	add_child(vbc)
	vbc.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	
	var tob_bar : HBoxContainer = HBoxContainer.new()
	vbc.add_child(tob_bar)
	
	file_btn = MenuButton.new()
	tob_bar.add_child(file_btn)
	file_btn.text = "File"
	
	file_btn_popup = file_btn.get_popup()
	
	var hotkey : InputEventKey = InputEventKey.new()
	hotkey.scancode = KEY_N
	hotkey.control = true
	file_btn_popup.add_item("New File", FileMenuOptions.FILE_MENU_OPTION_NEW, hotkey.get_scancode_with_modifiers())
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_O
	hotkey.control = true
	file_btn_popup.add_item("Open File", FileMenuOptions.FILE_MENU_OPTION_OPEN, hotkey.get_scancode_with_modifiers())
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_C
	hotkey.control = true
	hotkey.alt = true
	file_btn_popup.add_item("Close File", FileMenuOptions.FILE_MENU_OPTION_CLOSE, hotkey.get_scancode_with_modifiers())
	
	file_btn_popup.add_separator()
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_S
	hotkey.control = true
	file_btn_popup.add_item("Save File", FileMenuOptions.FILE_MENU_OPTION_SAVE, hotkey.get_scancode_with_modifiers())
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_S
	hotkey.control = true
	hotkey.alt = true
	file_btn_popup.add_item("Save File as...", FileMenuOptions.FILE_MENU_OPTION_SAVE_AS, hotkey.get_scancode_with_modifiers())
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_D
	hotkey.control = true
	file_btn_popup.add_item("Delete File", FileMenuOptions.FILE_MENU_OPTION_DELETE, hotkey.get_scancode_with_modifiers())
	
	file_btn_popup.add_separator()
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_F
	hotkey.control = true
	file_btn_popup.add_item("Search in file...", FileMenuOptions.FILE_MENU_OPTION_SEARCH, hotkey.get_scancode_with_modifiers())
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_R
	hotkey.control = true
	file_btn_popup.add_item("Replace occurencies", FileMenuOptions.FILE_MENU_OPTION_REPLACE, hotkey.get_scancode_with_modifiers())
	
	#Preview
	preview_btn = MenuButton.new()
	tob_bar.add_child(preview_btn)
	preview_btn.text = "Preview"
	
	preview_btn_popup = preview_btn.get_popup()
	
	preview_btn_popup.add_item("BBCode Preview")
	preview_btn_popup.add_item("Markdown Preview")
	preview_btn_popup.add_item("HTML Preview")
	preview_btn_popup.add_item("CSV Preview")
	
	#Settings
	settings_btn = MenuButton.new()
	tob_bar.add_child(settings_btn)
	settings_btn.text = "Settings"
	
	settings_btn_popup = settings_btn.get_popup()
	
	settings_btn_popup.add_item("Change Font")
	
	#SplitContainer
	editor_container = HSplitContainer.new()
	vbc.add_child(editor_container)
	editor_container.split_offset = 150
	editor_container.size_flags_horizontal = SIZE_EXPAND_FILL
	editor_container.size_flags_vertical = SIZE_EXPAND_FILL
	
	#Files
	file_container = VBoxContainer.new()
	editor_container.add_child(file_container)
	
	open_file_list = ItemList.new()
	file_container.add_child(open_file_list)
	open_file_list.allow_reselect = true
	open_file_list.size_flags_vertical = SIZE_EXPAND_FILL
	
	file_container.add_child(HSeparator.new())
	
	#Editor
	split_editor_container = VBoxContainer.new()
	editor_container.add_child(split_editor_container)
	
	var editor_top_bar : HBoxContainer = HBoxContainer.new()
	split_editor_container.add_child(editor_top_bar)
	
	var edtopbar_label : Label = Label.new()
	editor_top_bar.add_child(edtopbar_label)
	edtopbar_label.text = "Editing file:"
	
	open_file_name = LineEdit.new()
	editor_top_bar.add_child(open_file_name)
	open_file_name.editable = false
	open_file_name.mouse_filter = Control.MOUSE_FILTER_PASS
	open_file_name.size_flags_horizontal = SIZE_EXPAND_FILL
	
	wrap_btn = OptionButton.new()
	editor_top_bar.add_child(wrap_btn)
	wrap_btn.add_item("No Wrap")
	wrap_btn.add_item("Soft Wrap")
	
	map_btn = OptionButton.new()
	editor_top_bar.add_child(map_btn)
	map_btn.add_item("Hide Map")
	map_btn.add_item("Show Map")
	map_btn.selected = 1
	
	#dialogs
	file_list = FileDialog.new()
	add_child(file_list)
	file_list.show_hidden_files = true
	file_list.dialog_hide_on_ok = true
	file_list.window_title = "Save file"
	file_list.popup_exclusive = true
	file_list.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	file_list.margin_left = 222
	file_list.margin_top = 132
	file_list.margin_right = -221
	file_list.margin_bottom = -131
	file_list.rect_min_size = Vector2(200, 70)
	
	new_file_dialogue = AcceptDialog.new()
	add_child(new_file_dialogue)
	new_file_dialogue.window_title = "Create new File"
	
	var nfd_vbc : VBoxContainer = VBoxContainer.new()
	new_file_dialogue.add_child(nfd_vbc)
	
	var nfd_name : Label = Label.new()
	nfd_vbc.add_child(nfd_name)
	nfd_name.text = "Insert file name (no extension needed)"
	nfd_name.align = Label.ALIGN_CENTER
	nfd_name.valign = Label.VALIGN_CENTER
	nfd_name.size_flags_vertical = SIZE_EXPAND_FILL
	
	new_file_dialogue_name = LineEdit.new()
	nfd_vbc.add_child(new_file_dialogue_name)
	new_file_dialogue_name.clear_button_enabled = true
	new_file_dialogue_name.text = "example"
	new_file_dialogue_name.rect_min_size = Vector2(200, 0)
	new_file_dialogue_name.size_flags_horizontal = SIZE_EXPAND | SIZE_SHRINK_CENTER
	new_file_dialogue_name.size_flags_vertical = SIZE_EXPAND_FILL
	
	confirmation_close = ConfirmationDialog.new()
	add_child(confirmation_close)
	confirmation_close.dialog_text = "There are some unsaved changes.\nPress \"OK\" if you want to close this tab anyway, or \"cancel\" if you want to keep on editing your file."
	confirmation_close.window_title = "Unsaved changes"
	confirmation_close.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	
	select_font_dialog = FileDialog.new()
	add_child(select_font_dialog)
	select_font_dialog.mode = FileDialog.MODE_OPEN_FILE
	select_font_dialog.access = FileDialog.ACCESS_FILESYSTEM
	select_font_dialog.show_hidden_files = true
	select_font_dialog.window_title = "Open a File"
	select_font_dialog.resizable = true
	select_font_dialog.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	select_font_dialog.margin_left = 222
	select_font_dialog.margin_top = 132
	select_font_dialog.margin_right = -221
	select_font_dialog.margin_bottom = -131
	select_font_dialog.rect_min_size = Vector2(200, 70)
	
	var farr : PoolStringArray = PoolStringArray()
	farr.push_back("*.TTF")
	farr.push_back("*.ttf")
	select_font_dialog.filters = farr


func _ready():
	if not Engine.is_editor_hint():
		return
		
	clean_editor()
	connect_signals()
	
	var opened_files : Array = LastOpenedFiles.load_opened_files()
	for opened_file in opened_files:
		open_file(opened_file[1], opened_file[2])
		
	file_list.set_filters(EXTENSIONS)


func connect_signals():
	file_list.connect("confirmed",self,"update_list")
	file_btn_popup.connect("id_pressed",self,"_on_file_btn_pressed")
	preview_btn_popup.connect("id_pressed",self,"_on_preview_btn_pressed")
	settings_btn_popup.connect("id_pressed",self,"_on_settings_btn_pressed")
	
	open_file_list.connect("item_selected",self,"_on_fileitem_pressed")
	wrap_btn.connect("item_selected",self,"on_wrap_button")
	map_btn.connect("item_selected",self,"on_minimap_button")
	
	select_font_dialog.connect("file_selected",self,"_on_font_selected")


func create_selected_file():
		update_list()
		
		file_list.mode = FileDialog.MODE_SAVE_FILE
		file_list.set_title("Create a new File")
		
		if file_list.is_connected("file_selected",self,"delete_file"):
				file_list.disconnect("file_selected",self,"delete_file")
				
		if file_list.is_connected("file_selected",self,"open_file"):
				file_list.disconnect("file_selected",self,"open_file")
				
		if not file_list.is_connected("file_selected",self,"create_new_file"):
				file_list.connect("file_selected",self,"create_new_file")
				
		open_file_list()

func open_selected_file():
		update_list()
		
		file_list.mode = FileDialog.MODE_OPEN_FILE
		file_list.set_title("Select a File you want to edit")
		
		if file_list.is_connected("file_selected",self,"delete_file"):
				file_list.disconnect("file_selected",self,"delete_file")
				
		if file_list.is_connected("file_selected",self,"create_new_file"):
				file_list.disconnect("file_selected",self,"create_new_file")
				
		if not file_list.is_connected("file_selected",self,"open_file"):
				file_list.connect("file_selected",self,"open_file")
				
		open_file_list()

func delete_selected_file():
		update_list()
		
		file_list.mode = FileDialog.MODE_OPEN_FILES
		file_list.set_title("Select one or more Files you want to delete")
		
		if file_list.is_connected("file_selected",self,"open_file"):
				file_list.disconnect("file_selected",self,"open_file")
				
		if file_list.is_connected("file_selected",self,"create_new_file"):
				file_list.disconnect("file_selected",self,"create_new_file")
				
		if not file_list.is_connected("files_selected",self,"delete_file"):
				file_list.connect("files_selected",self,"delete_file")
				
		open_file_list()

func save_current_file_as():
		update_list()
		file_list.mode = FileDialog.MODE_SAVE_FILE
		file_list.set_title("Save this File as...")
		
		if file_list.is_connected("file_selected",self,"delete_file"):
				file_list.disconnect("file_selected",self,"delete_file")
				
		if file_list.is_connected("file_selected",self,"open_file"):
				file_list.disconnect("file_selected",self,"open_file")
				
		if not file_list.is_connected("file_selected",self,"create_new_file"):
				file_list.connect("file_selected",self,"create_new_file")
				
		open_file_list()

func _on_file_btn_pressed(index : int):
		match index:
				FileMenuOptions.FILE_MENU_OPTION_NEW:
						create_selected_file()
				FileMenuOptions.FILE_MENU_OPTION_OPEN:
						open_selected_file()
				FileMenuOptions.FILE_MENU_OPTION_CLOSE:
						if current_file_index!=-1 and current_file_path != "":
								close_file(current_file_index)
				
				FileMenuOptions.FILE_MENU_OPTION_SAVE:
						if current_file_index!=-1 and current_file_path != "":
								save_as = false

								save_file(current_file_path)
				FileMenuOptions.FILE_MENU_OPTION_SAVE_AS:
						if current_file_index!=-1 and current_file_path != "":
								save_as = true
								save_file(current_file_path)
								save_current_file_as()
				FileMenuOptions.FILE_MENU_OPTION_DELETE:
						delete_selected_file()
				FileMenuOptions.FILE_MENU_OPTION_SEARCH:
						current_editor.open_search_box()
				FileMenuOptions.FILE_MENU_OPTION_REPLACE:
						current_editor.open_replace_box()

func _on_preview_btn_pressed(id : int):
		if id == 0:
				bbcode_preview()
		elif id == 1:
				markdown_preview()
		elif id == 2:
				html_preview()
		elif id == 3:
				csv_preview()

func _on_settings_btn_pressed(index : int):
	match index:
		0:
			select_font_dialog.popup()

func _on_font_selected(font_path : String):
	current_editor.set_font(font_path)
	LastOpenedFiles.store_editor_fonts(current_file_path.get_file(), font_path)

func _on_fileitem_pressed(index : int):
	current_file_index = index
	var selected_item_metadata = open_file_list.get_item_metadata(current_file_index)
	var extension = selected_item_metadata[0].current_path.get_file().get_extension()
	
	if open_file_list.get_item_text(current_file_index).begins_with("(*)"):
		editing_file = true
	else:
		editing_file = false
		
	current_file_path = selected_item_metadata[0].current_path
	
	if current_editor.visible or current_editor == null:
		if current_editor != null:
			current_editor.hide()
		
		current_editor = selected_item_metadata[0]
		current_editor.show()
		open_file_name.set_text(current_editor.current_path)

		if wrap_btn.get_selected_id() == 1:
			current_editor.set_wrap_enabled(true)
		else:
			current_editor.set_wrap_enabled(false)
			
		if map_btn.get_selected_id() == 1:
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
		
		LastOpenedFiles.store_opened_files(open_file_list)
		
	current_editor.show()

func generate_file_item(path : String , veditor : Control):
	open_file_name.set_text(path)
	open_file_list.add_item(path.get_file(),IconLoader.load_icon_from_name("file"),true)
	
	current_file_index = open_file_list.get_item_count()-1
	
	open_file_list.set_item_metadata(current_file_index,[veditor])
	open_file_list.select(open_file_list.get_item_count()-1)

func open_in_vanillaeditor(path : String) -> Control:
	var editor = VanillaEditor.new()
	split_editor_container.add_child(editor,true)
	
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
	
	if wrap_btn.get_selected_id() == 1:
		current_editor.set_wrap_enabled(true)
	
	return editor

func close_file(index):
	if editing_file:
		confirmation_close.popup()
	else:
		confirm_close(index)

func confirm_close(index):
	LastOpenedFiles.remove_opened_file(index,open_file_list)
	open_file_list.remove_item(index)
	open_file_name.clear()
	current_editor.queue_free()
	
	if index > 0:
		open_file_list.select(index-1)
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

func open_new_file_dialogue():
	new_file_dialogue.popup()
	new_file_dialogue.set_position(OS.get_screen_size()/2 - new_file_dialogue.get_size()/2)

func open_file_list():
	update_list()
	file_list.popup()
	file_list.set_position(OS.get_screen_size()/2 - file_list.get_size()/2)

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
	
		
	open_file_list.set_item_metadata(current_file_index,[current_editor])
	
	if open_file_list.get_item_text(current_file_index).begins_with("(*)"):
		open_file_list.set_item_text(current_file_index,open_file_list.get_item_text(current_file_index).lstrip("(*)"))
		editing_file = false
	
	update_list()

func clean_editor() -> void :
	for vanillaeditor in get_tree().get_nodes_in_group("vanilla_editor"):
		vanillaeditor.queue_free()
		
	open_file_name.clear()
	open_file_list.clear()


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
	if not open_file_list.get_item_text(current_file_index).begins_with("(*)"):
		open_file_list.set_item_text(current_file_index,"(*)"+open_file_list.get_item_text(current_file_index))
		editing_file = true

func update_list():
		file_list.invalidate()

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
