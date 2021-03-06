tool
extends GDScript

const FORMAT_TEXTURE_PACKER_XML = 0
const FORMAT_TEXTURE_PACKER_JSON = 1
const FORMAT_KENNEY_XML = 2

var imagePath = ""
var width = 0
var height = 0
var sprites = []

class SpriteFrame extends Reference:
	var name = ""
	var region = Rect2(0, 0, 0, 0)
	var originFrame = Rect2(0, 0, 0, 0)
	var pivot = Vector2(0, 0)
	var rotation = 0


func loadFromFile(path, format):
	var file = File.new()
	file.open(path, File.READ)
	if file.is_open():
		var fileContent = file.get_as_text()
		_parse(fileContent, format)
	file.close()
	return self

func _parse(fileContent, format):
	var atlas = null
	self.sprites.clear()
	if format == FORMAT_TEXTURE_PACKER_XML:
		atlas = _parseTexturePackerXML(fileContent)
	elif format == FORMAT_TEXTURE_PACKER_JSON:
		atlas = _parseTexturePackerJson(fileContent)
	elif format == FORMAT_KENNEY_XML:
		atlas = _parseKenneyXML(fileContent)
	if atlas != null:
		if atlas.has("imagePath"):
			self.imagePath = atlas["imagePath"]
		if atlas.has("width"):
			self.width = atlas["width"]
		if atlas.has("height"):
			self.height = atlas["height"]
		if atlas.has("sprites"):
			for f in atlas["sprites"]:
				var sprite = SpriteFrame.new()
				sprite.name = f["name"]
				sprite.region = Rect2( f["x"] , f["y"], f["width"], f["height"])
				sprite.originFrame = Rect2( f["orignX"] , f["orignY"], f["orignWidth"], f["orignHeight"])
				sprite.pivot = Vector2(f["pivotX"], f["pivotY"])
				sprite.rotation = f["rotation"]
				self.sprites.append(sprite)
	return self

func _parseTexturePackerXML(xmlContent):
	"""
	Parse Atlas from XML content which is exported with TexturePacker as "XML(generic)"
	"""
	var atlas = null
	var sprites = []
	var xmlParser = XMLParser.new()
	if OK == xmlParser.open_buffer(xmlContent.to_utf8()):
		var err = xmlParser.read()
		if err == OK:
			atlas = {}
			atlas["sprites"] = sprites
		while(err != ERR_FILE_EOF):
			if xmlParser.get_node_type() == xmlParser.NODE_ELEMENT:
				if xmlParser.get_node_name() == "TextureAtlas":
					atlas["imagePath"] = xmlParser.get_named_attribute_value("imagePath")
					atlas["width"] = xmlParser.get_named_attribute_value("width")
					atlas["height"] = xmlParser.get_named_attribute_value("height")
				elif xmlParser.get_node_name() == "sprite":
					var sprite = {}
					sprite["name"] = xmlParser.get_named_attribute_value("n")
					sprite["x"] = xmlParser.get_named_attribute_value("x")
					sprite["y"] = xmlParser.get_named_attribute_value("y")
					sprite["width"] = xmlParser.get_named_attribute_value("w")
					sprite["height"] = xmlParser.get_named_attribute_value("h")
					sprite["pivotX"] = xmlParser.get_named_attribute_value("pX")
					sprite["pivotY"] = xmlParser.get_named_attribute_value("pY")
					if xmlParser.has_attribute("oX"):
						sprite["orignX"] = xmlParser.get_named_attribute_value("oX")
					else:
						sprite["orignX"] = 0.0
					if xmlParser.has_attribute("oY"):
						sprite["orignY"] = xmlParser.get_named_attribute_value("oY")
					else:
						sprite["orignY"] = 0.0
					if xmlParser.has_attribute("oW"):
						sprite["orignWidth"] = xmlParser.get_named_attribute_value("oW")
					else:
						sprite["orignWidth"] = 0.0
					if xmlParser.has_attribute("oH"):
						sprite["orignHeight"] = xmlParser.get_named_attribute_value("oH")
					else:
						sprite["orignHeight"] = 0.0
					if xmlParser.has_attribute("r") and xmlParser.get_named_attribute_value("r") == "y":
						sprite["rotation"] = deg2rad(90)
					else:
						sprite["rotation"] = 0
					sprites.append(sprite)
			err = xmlParser.read()
	return atlas

func _parseTexturePackerJson(jsonContent):
	"""
	Parse Atlas from json content which is exported from TexturePacker as "JSON"
	"""
	var atlas = null
	var sprites = []

	var jsonParser = parse_json(jsonContent)
	if typeof(jsonParser) == TYPE_DICTIONARY:
		atlas = {}
		atlas["sprites"] = sprites
		if jsonParser.has("meta") and jsonParser.has("frames"):
			atlas["imagePath"] = jsonParser["meta"]["image"]
			atlas["width"] = jsonParser["meta"]["size"]["w"]
			atlas["height"] = jsonParser["meta"]["size"]["h"]
			var frames = jsonParser["frames"]
			for key in frames.keys():
				var sprite = {}
				var f = frames[key]
				sprite["name"] = key
				sprite["x"] = f["frame"]["x"]
				sprite["y"] = f["frame"]["y"]
				sprite["width"] = f["frame"]["w"]
				sprite["height"] = f["frame"]["h"]
				sprite["pivotX"] = f["pivot"]["x"]
				sprite["pivotY"] = f["pivot"]["y"]
				sprite["orignX"] = f["spriteSourceSize"]["x"]
				sprite["orignY"] = f["spriteSourceSize"]["y"]
				sprite["orignWidth"] = f["spriteSourceSize"]["w"]
				sprite["orignHeight"] = f["spriteSourceSize"]["h"]
				sprite["rotation"] = 0
				if f["rotated"]:
					sprite["rotation"] = deg2rad(90)
				sprites.append(sprite)
	return atlas

func _parseKenneyXML(xmlContent):
	"""
	Parse Atlas from XML content which is in a Kenney Spritesheet format
	"""
	var atlas = null
	var sprites = []
	var xmlParser = XMLParser.new()
	if OK == xmlParser.open_buffer(xmlContent.to_utf8()):
		var err = xmlParser.read()
		if err == OK:
			atlas = {}
			atlas["sprites"] = sprites
		while(err != ERR_FILE_EOF):
			if xmlParser.get_node_type() == xmlParser.NODE_ELEMENT:
				if xmlParser.get_node_name() == "TextureAtlas":
					# NOTE: Kenney XML file <TextureAtlas> tags don't seem to provide height or width
					atlas["imagePath"] = xmlParser.get_named_attribute_value("imagePath")
				elif xmlParser.get_node_name() == "SubTexture":
					var sprite = {}
					sprite["name"] = xmlParser.get_named_attribute_value("name")
					sprite["x"] = xmlParser.get_named_attribute_value("x")
					sprite["y"] = xmlParser.get_named_attribute_value("y")
					sprite["width"] = xmlParser.get_named_attribute_value("width")
					sprite["height"] = xmlParser.get_named_attribute_value("height")
					sprite["pivotX"] = 0
					sprite["pivotY"] = 0
					sprite["orignX"] = 0.0
					sprite["orignY"] = 0.0
					sprite["orignWidth"] = 0.0
					sprite["orignHeight"] = 0.0
					sprite["rotation"] = 0
					sprites.append(sprite)
			err = xmlParser.read()
	return atlas
