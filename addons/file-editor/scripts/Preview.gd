tool
extends WindowDialog

var text_preview : RichTextLabel = null
var table_preview : GridContainer = null

signal image_downloaded()
signal image_loaded()

func _init() -> void:
	window_title = "File preview"
	resizable = true
	set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margin_left = 81
	margin_top = 47
	margin_right = -80
	margin_bottom = -48
	
	var vbc : VBoxContainer = VBoxContainer.new()
	vbc.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	add_child(vbc)
	
	text_preview = RichTextLabel.new()
	vbc.add_child(text_preview)
	text_preview.scroll_following = true
	text_preview.bbcode_enabled = true
	text_preview.size_flags_vertical = SIZE_EXPAND_FILL
	text_preview.hide()
	
	table_preview = GridContainer.new()
	vbc.add_child(table_preview)
	table_preview.columns = 3
	table_preview.size_flags_horizontal = SIZE_EXPAND_FILL
	table_preview.size_flags_vertical = SIZE_EXPAND_FILL
	table_preview.hide()
	
	connect("popup_hide", self, "_on_Preview_popup_hide")

func print_preview(content : String) -> void:
	text_preview.append_bbcode(content)
	text_preview.show()

func print_bb(content : String) -> void:
	text_preview.append_bbcode(content)
	text_preview.show()

func print_markdown(content : String) -> void:
	var result : Array = Array()
	var bolded : Array = Array()
	var italics : Array = Array()
	var striked : Array = Array()
	var coded : Array = Array()
	var linknames : Array = Array()
	var images : Array = Array()
	var links : Array = Array()
	var lists : Array = Array()
	var underlined : Array = Array()
	
	var regex : RegEx = RegEx.new()
	regex.compile('\\*\\*(?<boldtext>.*)\\*\\*')
	result = regex.search_all(content)
	for i in range(result.size()):
		var res : RegExMatch = result[i]
		bolded.append(res.get_string("boldtext"))
	
	regex.compile('\\_\\_(?<underlinetext>.*)\\_\\_')
	result = regex.search_all(content)
	for i in range(result.size()):
		var res : RegExMatch = result[i]
		underlined.append(res.get_string("underlinetext"))
	
	regex.compile("\\*(?<italictext>.*)\\*")
	result = regex.search_all(content)
	for i in range(result.size()):
		var res : RegExMatch = result[i]
		italics.append(res.get_string("italictext"))
	
	regex.compile("~~(?<strikedtext>.*)~~")
	result = regex.search_all(content)
	for i in range(result.size()):
		var res : RegExMatch = result[i]
		striked.append(res.get_string("strikedtext"))
	
	regex.compile("`(?<coded>.*)`")
	result = regex.search_all(content)
	for i in range(result.size()):
		var res : RegExMatch = result[i]
		coded.append(res.get_string("coded"))
	
	regex.compile("[+-*](?<element>\\s.*)")
	result = regex.search_all(content)
	for i in range(result.size()):
		var res : RegExMatch = result[i]
		lists.append(res.get_string("element"))
	
	regex.compile("(?<img>!\\[.*?\\))")
	result = regex.search_all(content)
	for i in range(result.size()):
		var res : RegExMatch = result[i]
		images.append(res.get_string("img"))
	
	regex.compile("\\[(?<linkname>.*?)\\]|\\((?<link>[h\\.]\\S*?)\\)")
	result = regex.search_all(content)
	for i in range(result.size()):
		var res : RegExMatch = result[i]
		
		if res.get_string("link")!="":
			links.append(res.get_string("link"))
			
		if res.get_string("linkname")!="":
			linknames.append(res.get_string("linkname"))
	
	for i in range(bolded.size()):
		var bold : String = bolded[i]
		content = content.replace("**"+bold+"**","[b]"+bold+"[/b]")
	
	for i in range(italics.size()):
		var italic : String = italics[i]
		content = content.replace("*"+italic+"*","[i]"+italic+"[/i]")
		
	for i in range(striked.size()):
		var strik : String = striked[i]
		content = content.replace("~~"+strik+"~~","[s]"+strik+"[/s]")
	
	for i in range(underlined.size()):
		var underline : String = underlined[i]
		content = content.replace("__"+underline+"__","[u]"+underline+"[/u]")
	
	for i in range(coded.size()):
		var code : String = coded[i]
		content = content.replace("`"+code+"`","[code]"+code+"[/code]")
	
	for i in range(images.size()):
		var image : String = images[i]
		var substr = image.split("(")
		var imglink = substr[1].rstrip(")")
		content = content.replace(image,"[img]"+imglink+"[/img]")
	
	for i in links.size():
		content = content.replace("["+linknames[i]+"]("+links[i]+")","[url="+links[i]+"]"+linknames[i]+"[/url]")
	
	for i in range(lists.size()):
		var element : String = lists[i]

		if content.find("- "+element):
			content = content.replace("-"+element,"[indent]-"+element+"[/indent]")
			
		if content.find("+ "+element):
			content = content.replace("+"+element,"[indent]-"+element+"[/indent]")
			
		if content.find("* "+element):
			content = content.replace("+"+element,"[indent]-"+element+"[/indent]")
	
	text_preview.append_bbcode(content)
	text_preview.show()

func print_html(content : String) -> void:
	content = content.replace("<i>","[i]")
	content = content.replace("</i>","[/i]")
	content = content.replace("<b>","[b]")
	content = content.replace("</b>","[/b]")
	content = content.replace("<u>","[u]")
	content = content.replace("</u>","[/u]")
	content = content.replace("<ins>","[u]")
	content = content.replace("</ins>","[/u]")
	content = content.replace("<del>","[s]")
	content = content.replace("</del>","[/s]")
	content = content.replace('<a href="',"[url=")
	content = content.replace('">',"]")
	content = content.replace("</a>","[/url]")
	content = content.replace('<img src="',"[img]")
	content = content.replace('" />',"[/img]")
	content = content.replace('"/>',"[/img]")
	content = content.replace("<pre>","[code]")
	content = content.replace("</pre>","[/code]")
	content = content.replace("<center>","[center]")
	content = content.replace("</center>","[/center]")
	content = content.replace("<right>","[right]")
	content = content.replace("</right>","[/right]")
	
	text_preview.append_bbcode(content)
	text_preview.show()

func print_csv(rows : Array) -> void:
	table_preview.columns = rows[0].size()
	for item in rows:
		for string in item:
			var label = Label.new()
			label.text = str(string)
			label.set_h_size_flags(SIZE_EXPAND)
			label.set_align(1)
			label.set_valign(1)
			table_preview.add_child(label)
	
	table_preview.show()

func _on_Preview_popup_hide() -> void:
	queue_free()
