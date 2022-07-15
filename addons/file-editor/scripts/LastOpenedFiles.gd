tool
extends Reference

var editor_plugin : EditorPlugin = null
var editor_settings : EditorSettings = null

func store_opened_files(filecontainer : Control):
	var arr : Array = Array()
	
	for child in range(filecontainer.get_item_count()):
		var filepath : String = filecontainer.get_item_metadata(child)[0].current_path
		
		var a : Array = Array()
		a.push_back(filepath.get_file())
		a.push_back(filepath)
		
		arr.push_back(a)
	
	editor_settings.set_project_metadata("file_editor", "files", arr)

func remove_opened_file(index : int , filecontainer : Control):
	var filepath : String = filecontainer.get_item_metadata(index)[0].current_path
	var f : String = filepath.get_file()
	
	var arr : Array = editor_settings.get_project_metadata("file_editor", "files", Array())
	
	for i in range(arr.size()):
		var a : Array = arr[i]
		
		if a[0] == f:
			arr.remove(i)
			break
	
	editor_settings.set_project_metadata("file_editor", "files", arr)
	
	var fonts_dict : Dictionary = editor_settings.get_project_metadata("file_editor", "file_fonts", Dictionary())
	
	if fonts_dict.has(f):
		fonts_dict.erase(f)
		editor_settings.set_project_metadata("file_editor", "file_fonts", fonts_dict)

func load_opened_files() -> Array:
	var arr : Array = editor_settings.get_project_metadata("file_editor", "files", Array())
	var fonts_dict : Dictionary = editor_settings.get_project_metadata("file_editor", "file_fonts", Dictionary())
	var keys : Array  = Array()
	for i in range(arr.size()):
		var a : Array = arr[i]
		
		# creating and returning an Array with this format [1:file name, 2:file path, 3:file font]
		var k : Array
		k.push_back(a[0])
		k.push_back(a[1])
		
		if fonts_dict.has(a[0]):
			k.push_back(fonts_dict[a[0]])
		else:
			k.push_back("null")
		
		keys.append(k)
		
	return keys

func store_editor_fonts(file_name : String, font_path : String):
	var fonts_dict : Dictionary = editor_settings.get_project_metadata("file_editor", "file_fonts", Dictionary())
	fonts_dict[file_name] = font_path
	editor_settings.set_project_metadata("file_editor", "file_fonts", fonts_dict)


func get_editor_font() -> String:
	#var editor_plugin : EditorPlugin = EditorPlugin.new()
	return editor_plugin.get_editor_interface().get_editor_settings().get_setting("interface/editor/code_font")
