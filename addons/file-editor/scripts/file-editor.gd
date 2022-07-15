tool
extends EditorPlugin

var IconLoader = preload("res://addons/file-editor/scripts/IconLoader.gd").new()
var LastOpenedFiles = preload("res://addons/file-editor/scripts/LastOpenedFiles.gd").new()

var FileEditor

func _enter_tree():
	LastOpenedFiles.editor_plugin = self
	LastOpenedFiles.editor_settings = get_editor_interface().get_editor_settings()
	
	FileEditor = preload("res://addons/file-editor/scripts/FileEditor.gd").new()
	FileEditor.LastOpenedFiles = LastOpenedFiles
	get_editor_interface().get_editor_viewport().add_child(FileEditor)
	FileEditor.hide()

func _exit_tree():
	get_editor_interface().get_editor_viewport().remove_child(FileEditor)

func has_main_screen():
	return true

func get_plugin_name():
	return "File"

func get_plugin_icon():
	return IconLoader.load_icon_from_name("file")

func make_visible(visible):
	FileEditor.visible = visible
