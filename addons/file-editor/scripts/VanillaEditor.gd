tool
extends VBoxContainer

var LastOpenedFiles = preload("res://addons/file-editor/scripts/LastOpenedFiles.gd").new()

var text_editor : TextEdit = null

var FileList
var ClosingFile

var search_box : HBoxContainer = null
var search_box_line_edit : LineEdit = null
var search_box_match_case_cb : CheckBox = null
var search_box_whole_words_cb : CheckBox = null
var search_box_close_button : Button = null

var replace_box : HBoxContainer = null
var replace_box_replace_le : LineEdit = null
var replace_box_with : LineEdit = null
var replace_box_button : Button = null
var replace_box_close : Button = null

var file_info_last_modified_icon : TextureRect = null
var file_info_last_modified : Label = null
var file_info_c_counter : Label = null
var file_info_read_only : CheckBox = null

var current_path = ""
var current_filename = ""

var search_flag = 0

signal text_changed()

func _init():
	size_flags_vertical = SIZE_EXPAND_FILL
	set_anchors_and_margins_preset(Control.PRESET_WIDE)
	
	text_editor = TextEdit.new()
	add_child(text_editor)
	text_editor.highlight_current_line = true
	text_editor.syntax_highlighting = true
	text_editor.show_line_numbers = true
	text_editor.breakpoint_gutter = true
	text_editor.highlight_all_occurrences = true
	text_editor.override_selected_font_color = true
	text_editor.smooth_scrolling = true
	text_editor.hiding_enabled = true
	#todo look this up from the editor settings
	#text_editor.caret_blink = true
	#text_editor.caret_blink_speed = 1
	text_editor.caret_moving_by_right_click = false
	text_editor.minimap_draw = true
	text_editor.size_flags_vertical = SIZE_EXPAND_FILL
	text_editor.set("custom_colors/member_variable_color", Color(0.737255, 0.882353, 1))
	text_editor.set("custom_colors/code_folding_color", Color(1, 1, 1, 0.701961))
	text_editor.set("custom_colors/function_color", Color(0.341176, 0.701961, 1))
	text_editor.set("custom_colors/safe_line_number_color", Color(0.8, 0.968627, 0.827451, 0.74902))
	text_editor.set("custom_colors/symbol_color", Color(0.670588, 0.788235, 1))
	text_editor.set("custom_colors/caret_background_color", Color(0, 0, 0))
	text_editor.set("custom_colors/selection_color", Color(0.411765, 0.611765, 0.909804, 0.34902))
	text_editor.set("custom_colors/caret_color", Color(1, 1, 1))
	text_editor.set("custom_colors/breakpoint_color", Color(1, 0.470588, 0.419608))
	text_editor.set("custom_colors/font_color_selected", Color(0, 0, 0))
	text_editor.set("custom_colors/font_color", Color(1, 1, 1))
	text_editor.set("custom_colors/completion_font_color", Color(1, 1, 1, 0.392157))
	text_editor.set("custom_colors/completion_scroll_color", Color(1, 1, 1, 0.070588))
	text_editor.set("custom_colors/background_color", Color(0.121569, 0.145098, 0.192157))
	text_editor.set("custom_colors/number_color", Color(0.631373, 1, 0.882353))
	text_editor.set("custom_colors/completion_background_color", Color(0.196078, 0.231373, 0.309804))
	text_editor.set("custom_colors/brace_mismatch_color", Color(1, 0.470588, 0.419608))
	text_editor.set("custom_colors/current_line_color", Color(1, 1, 1, 0.070588))
	text_editor.set("custom_colors/completion_selected_color", Color(1, 1, 1, 0.070588))
	text_editor.set("custom_colors/mark_color", Color(1, 0.470588, 0.419608, 0.301961))
	text_editor.set("custom_colors/word_highlighted_color", Color(1, 1, 1, 0.392157))
	text_editor.set("custom_colors/completion_existing_color", Color(1, 1, 1, 0.392157))
	text_editor.set("custom_constants/completion_lines", 20)
	text_editor.set("custom_constants/completion_max_width", 20)
	text_editor.set("custom_constants/completion_scroll_width", 20)
	#text_editor.owner = self
	
	search_box = HBoxContainer.new()
	add_child(search_box)
	search_box.hide()
	
	var selabel : Label = Label.new()
	search_box.add_child(selabel)
	selabel.text = "Search:"
	
	search_box_line_edit = LineEdit.new()
	search_box.add_child(search_box_line_edit)
	search_box_line_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	search_box_line_edit.connect("text_changed", self, "_on_LineEdit_text_changed")
	search_box_line_edit.connect("focus_entered", self, "_on_LineEdit_focus_entered")
	
	search_box_match_case_cb = CheckBox.new()
	search_box.add_child(search_box_match_case_cb)
	search_box_match_case_cb.text = "Match Case"
	search_box_match_case_cb.connect("toggled", self, "_on_matchcase_toggled")
	
	search_box_whole_words_cb = CheckBox.new()
	search_box.add_child(search_box_whole_words_cb)
	search_box_whole_words_cb.text = "Whole Words"
	search_box_whole_words_cb.connect("toggled", self, "_on_wholewords_toggled")
	
	search_box_close_button = Button.new()
	search_box.add_child(search_box_close_button)
	search_box_close_button.text = "x"
	search_box_close_button.flat = true
	search_box_whole_words_cb.connect("pressed", self, "_on_close_pressed")
	
	replace_box = HBoxContainer.new()
	add_child(replace_box)
	replace_box.hide()

	var rblabel : Label = Label.new()
	replace_box.add_child(rblabel)
	rblabel.text = "Replace:"
	
	replace_box_replace_le = LineEdit.new()
	replace_box.add_child(replace_box_replace_le)
	replace_box_replace_le.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var rb2label : Label = Label.new()
	replace_box.add_child(rb2label)
	rb2label.text = "With:"
	
	replace_box_with = LineEdit.new()
	replace_box.add_child(replace_box_with)
	replace_box_with.size_flags_horizontal = SIZE_EXPAND_FILL
	
	replace_box_button = Button.new()
	replace_box.add_child(replace_box_button)
	replace_box_button.text = "Replace"
	replace_box_button.connect("pressed", self, "_on_Button_pressed")
	
	replace_box_close = Button.new()
	replace_box.add_child(replace_box_close)
	replace_box_close.text = "x"
	replace_box_close.flat = true
	replace_box_button.connect("pressed", self, "_on_close2_pressed")
	
	var file_info : HBoxContainer = HBoxContainer.new()
	add_child(file_info)
	
	file_info_last_modified_icon = TextureRect.new()
	file_info.add_child(file_info_last_modified_icon)
	file_info_last_modified_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	
	var filabel : Label = Label.new()
	file_info.add_child(filabel)
	filabel.text = "Last modified time:"
	
	file_info_last_modified = Label.new()
	file_info.add_child(file_info_last_modified)
	
	var fi2label : Label = Label.new()
	file_info.add_child(fi2label)
	fi2label.text = "Characters counter:"
	fi2label.align = Label.ALIGN_RIGHT
	fi2label.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL | SIZE_SHRINK_CENTER | SIZE_SHRINK_END
	
	file_info_c_counter = Label.new()
	file_info.add_child(file_info_c_counter)
	file_info_c_counter.size_flags_horizontal = SIZE_EXPAND
	
	file_info_read_only = CheckBox.new()
	file_info.add_child(file_info_read_only)
	file_info_read_only.text = "Can Edit"
	file_info_read_only.flat = true
	file_info_read_only.size_flags_horizontal = SIZE_EXPAND | SIZE_SHRINK_END

func _ready():
	text_editor.connect("text_changed", self, "_on_TextEditor_text_changed")
	
	FileList = get_parent().get_parent().get_parent().get_parent().get_node("FileList")
	
	file_info_read_only.connect("toggled",self,"_on_Readonly_toggled")
	
	#file_info_read_only.set("custom_icons/checked",IconLoader.load_icon_from_name("read"))
	#file_info_read_only.set("custom_icons/unchecked",IconLoader.load_icon_from_name("edit"))
	
	add_to_group("vanilla_editor")
	load_default_font()

func set_font(font_path : String) -> void:
	var dynamic_font : DynamicFont = DynamicFont.new()
	var dynamic_font_data : DynamicFontData = DynamicFontData.new()
	dynamic_font_data.set_font_path(font_path)
	dynamic_font.set_font_data(dynamic_font_data)
	text_editor.set("custom_fonts/font",dynamic_font)

func load_default_font() -> void:
	var default_font = LastOpenedFiles.get_editor_font()
	if default_font:
		set_font(default_font)

func set_wrap_enabled(enabled:bool):
	text_editor.set_wrap_enabled(enabled)
	text_editor.update()

func draw_minimap(value:bool):
	text_editor.draw_minimap(value)
	text_editor.update()

func color_region(filextension : String): # -----------------------------> dal momento che voglio creare un editor per ogni file, renderò questa funzione singola in base all'estensione del file
	match(filextension):
		"bbs":
			text_editor.add_color_region("[b]","[/b]",Color8(153,153,255,255),false)
			text_editor.add_color_region("[i]","[/i]",Color8(153,255,153,255),false)
			text_editor.add_color_region("[s]","[/s]",Color8(255,153,153,255),false)
			text_editor.add_color_region("[u]","[/u]",Color8(255,255,102,255),false)
			text_editor.add_color_region("[url","[/url]",Color8(153,204,255,255),false)
			text_editor.add_color_region("[code]","[/code]",Color8(192,192,192,255),false)
			text_editor.add_color_region("[img]","[/img]",Color8(255,204,153,255),false)
			text_editor.add_color_region("[center]","[/center]",Color8(175,238,238,255),false)
			text_editor.add_color_region("[right]","[/right]",Color8(135,206,235,255),false)
		"html":
			text_editor.add_color_region("<b>","</b>",Color8(153,153,255,255),false)
			text_editor.add_color_region("<i>","</i>",Color8(153,255,153,255),false)
			text_editor.add_color_region("<del>","</del>",Color8(255,153,153,255),false)
			text_editor.add_color_region("<ins>","</ins>",Color8(255,255,102,255),false)
			text_editor.add_color_region("<a","</a>",Color8(153,204,255,255),false)
			text_editor.add_color_region("<img","/>",Color8(255,204,153,255),true)
			text_editor.add_color_region("<pre>","</pre>",Color8(192,192,192,255),false)
			text_editor.add_color_region("<center>","</center>",Color8(175,238,238,255),false)
			text_editor.add_color_region("<right>","</right>",Color8(135,206,235,255),false)
		"md":
			text_editor.add_color_region("***","***",Color8(126,186,181,255),false)
			text_editor.add_color_region("**","**",Color8(153,153,255,255),false)
			text_editor.add_color_region("*","*",Color8(153,255,153,255),false)
			text_editor.add_color_region("+ ","",Color8(255,178,102,255),false)
			text_editor.add_color_region("- ","",Color8(255,178,102,255),false)
			text_editor.add_color_region("~~","~~",Color8(255,153,153,255),false)
			text_editor.add_color_region("__","__",Color8(255,255,102,255),false)
			text_editor.add_color_region("[",")",Color8(153,204,255,255),false)
			text_editor.add_color_region("`","`",Color8(192,192,192,255),false)
			text_editor.add_color_region('"*.','"',Color8(255,255,255,255),true)
			text_editor.add_color_region("# ","",Color8(105,105,105,255),true)
			text_editor.add_color_region("## ","",Color8(128,128,128,255),true)
			text_editor.add_color_region("### ","",Color8(169,169,169,255),true)
			text_editor.add_color_region("#### ","",Color8(192,192,192,255),true)
			text_editor.add_color_region("##### ","",Color8(211,211,211,255),true)
			text_editor.add_color_region("###### ","",Color8(255,255,255,255),true)
			text_editor.add_color_region("> ","",Color8(172,138,79,255),true)
		"cfg":
			text_editor.add_color_region("[","]",Color8(153,204,255,255),false)
			text_editor.add_color_region('"','"',Color8(255,255,102,255),false)
			text_editor.add_color_region(';','',Color8(128,128,128,255),true)
		"ini":
			text_editor.add_color_region("[","]",Color8(153,204,255,255),false)
			text_editor.add_color_region('"','"',Color8(255,255,102,255),false)
			text_editor.add_color_region(';','',Color8(128,128,128,255),true)
		_:
			pass

func clean_editor():
	text_editor.set_text("")
	#file_info_last_modified_icon.texture = IconLoader.load_icon_from_name("save")
	file_info_last_modified.set_text("")
	FileList.invalidate()
	current_filename = ""
	current_path = ""

func new_file_open(file_content : String, last_modified : Dictionary, current_file_path : String):
	current_path = current_file_path
	current_filename = current_file_path.get_file()
	color_region(current_filename.get_extension())
	text_editor.set_text(file_content)
	update_lastmodified(last_modified,"save")
	FileList.invalidate()
	count_characters()

func update_lastmodified(last_modified : Dictionary, icon : String):
	file_info_last_modified.set_text(str(last_modified.hour)+":"+str(last_modified.minute)+"  "+str(last_modified.day)+"/"+str(last_modified.month)+"/"+str(last_modified.year))
	#file_info_last_modified_icon.texture = IconLoader.load_icon_from_name(icon)

func new_file_create(file_name):
	text_editor.set_text("")
	
	FileList.invalidate()

func _on_Readonly_toggled(button_pressed):
	if button_pressed:
		file_info_read_only.set_text("Read Only")
		text_editor.readonly = (true)
	else:
		file_info_read_only.set_text("Can Edit")
		text_editor.readonly = (false)

func _on_text_editor_text_changed():
	#file_info_last_modified_icon.texture = IconLoader.load_icon_from_name("saveas")
	count_characters()
	emit_signal("text_changed")

func count_characters():
	var counted : int = 0
	for line in text_editor.get_line_count():
		counted += text_editor.get_line(line).length()
		
	file_info_c_counter.set_text(str(counted))

func _on_LineEdit_text_changed(new_text):
	var linecount = text_editor.get_line_count()
	if new_text != "":
		var found
		var find = false
		for line in range(0,linecount):
			for column in range(0,text_editor.get_line(line).length()):
				found = text_editor.search( new_text, search_flag, line , column )
				if found.size():
					if found[1] == line:
#						if not find:
						text_editor.select(line,found[0],found[1],found[0]+new_text.length())
#							find = true
				else:
					text_editor.select(0,0,0,0)
	else:
		text_editor.select(0,0,0,0)

func _on_matchcase_toggled(button_pressed):
	if button_pressed:
		search_flag = 1
	else:
		if search_box_whole_words_cb.is_pressed():
			search_flag = 2
		else:
			search_flag = 0
			
	_on_LineEdit_text_changed(search_box_line_edit.get_text())

func _on_wholewords_toggled(button_pressed):
	if button_pressed:
		search_flag = 2
	else:
		if search_box_match_case_cb.is_pressed():
			search_flag = 1
		else:
			search_flag = 0
			
	_on_LineEdit_text_changed(search_box_line_edit.get_text())

func _on_close_pressed():
	search_box.hide()

func open_search_box():
	if search_box.visible:
		search_box.hide()
	else:
		search_box.show()
		search_box.get_node("LineEdit").grab_focus()

func _on_Button_pressed():
	var linecount = text_editor.get_line_count()-1
	var old_text = replace_box_replace_le.get_text()
	var new_text = replace_box_with.get_text()
	var text = text_editor.get_text()
	text_editor.set_text(text.replace(old_text,new_text))

func open_replace_box():
	if replace_box.visible:
		replace_box.hide()
	else:
		replace_box.show()
		replace_box.get_node("replace").grab_focus()

func _on_close2_pressed():
	replace_box.hide()

func _on_LineEdit_focus_entered():
	_on_LineEdit_text_changed(search_box_line_edit.get_text())
