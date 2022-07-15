tool
extends Node

func load_icon_from_name(icon_name : String) -> ImageTexture:
	var file : File = File.new()
	var image : Image = Image.new()
	var texture : ImageTexture = ImageTexture.new()
	
	file.open("res://addons/file-editor/icons.pngs/"+icon_name+".png.buttonicon", File.READ)
	var buffer : PoolByteArray = file.get_buffer(file.get_len())
	file.close()
	
	image.load_png_from_buffer(buffer)
	texture.create_from_image(image)
	return texture
