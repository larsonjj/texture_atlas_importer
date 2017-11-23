tool
extends EditorImportPlugin

var AtlasParser = preload("res://addons/texture_atlas_importer/atlas.gd")
var import_options_index = 0
var import_options_preset = AtlasParser.FORMAT_TEXTURE_JSON
var XML_NAME = "xml_map"
var JSON_NAME = "json_map"
var MESSAGE_PREFIX = "Atlas Importer -> "

func get_importer_name():
	return "io.jakelarson.godot.texture_atlas_importer"

func get_visible_name():
	return "Texture Atlas"

func get_recognized_extensions():
	return ["png", "jpeg", 'jpg']

func get_save_extension():
	return "tex"

func get_resource_type():
	return "Texture";

func get_preset_count():
	return 3

func get_preset_name(i):
	var json = "Texture Packer (JSON Hash)"
	var xml = "Texture Packer (Generic XML)"
	var kenney_xml = "Kenney Assets Spritesheet (XML)"
	var default = json
	if i == 0:
		return default
	elif i == 1:
		return xml
	elif i == 2:
		return kenney_xml
	else:
		return default

func get_option_visibility(option, options):
	if import_options_index == 0 and option == XML_NAME:
		import_options_preset = AtlasParser.FORMAT_TEXTURE_JSON
		return false
	elif import_options_index > 0 and option == JSON_NAME:
		if import_options_index == 1:
			import_options_preset = AtlasParser.FORMAT_TEXTURE_PACKER_XML
		if import_options_index == 1:
			import_options_preset = AtlasParser.FORMAT_KENNEY_SPRITESHEET
		return false
	else:
		return true

func get_import_options(i):
	# Keep track of which preset is selected within entire class
	import_options_index = i

	return [{
		"name": JSON_NAME,
		"default_value": "",
		"property_hint": PROPERTY_HINT_FILE,
		"hint_string": "*.json"
	}, {
		"name": XML_NAME,
		"default_value": "",
		"property_hint": PROPERTY_HINT_FILE,
		"hint_string": "*.xml"
	}, {
		"name": "Compression",
		"default_value": 0,
		"property_hint": PROPERTY_HINT_ENUM,
		"hint_string": "Lossless,Lossy,Uncompressed"
	}]

func _getFileName(path):
	var fileName = path.substr(path.find_last("/")+1, path.length() - path.find_last("/")-1)
	var dotPos = fileName.find_last(".")
	if dotPos != -1:
		fileName = fileName.substr(0,dotPos)
	return fileName


func _getParentDir(path):
	var fileName = path.substr(0, path.find_last("/"))
	return fileName

func _loadAtlas(path, format):
	var atlas = AtlasParser.new()
	atlas.loadFromFile(path, format)
	return atlas

func _loadAtlasTex(path, atlas):
	var src_path = str(_getParentDir(path), "/", atlas.imagePath)
	var tex = null
	if ResourceLoader.has(src_path):
		tex = ResourceLoader.load(src_path)
	else:
		tex = ImageTexture.new()
	tex.load(src_path)
	return tex


func save_files(source_file, save_path, options):
	var dest_path = save_path + "." + get_save_extension()
	var map = options.json_map if import_options_preset == AtlasParser.FORMAT_TEXTURE_JSON else options.xml_map

	if !map:
		printerr(MESSAGE_PREFIX + "ERROR: No map specified in Texture Atlas importer!")

	var atlas = _loadAtlas(map, import_options_preset)
	var tex = _loadAtlasTex(map, atlas)

	if not ResourceLoader.has(dest_path):
		tex.set_path(dest_path)
	else:
		tex.take_over_path(dest_path)
	tex.set_name(dest_path)
	if options.Compression == ImageTexture.STORAGE_COMPRESS_LOSSY:
		tex.set_lossy_storage_quality(0.7)
	var tex_err = ResourceSaver.save(dest_path, tex)

	if tex_err != OK:
		return tex_err

	var tarDir = _getParentDir(source_file)

	# Remove existing atlas textures
	var dir = Directory.new()
	if dir.open(tarDir) == OK:
		dir.list_dir_begin()
		var f = dir.get_next()
		while f.length():
			if f.begins_with(str(_getFileName(source_file), ".")) and f.ends_with(".atlastex") and dir.file_exists(f):
				dir.remove(f)
				print(MESSAGE_PREFIX + "Remove: ",f)
			f = dir.get_next()

	var err = OK
	# Generate new atlas textures
	for s in atlas.sprites:
		var atex = AtlasTexture.new()
		var ap = str(tarDir, "/", _getFileName(source_file), ".", _getFileName(s.name),".atlastex")
		atex.set_path(ap)
		atex.set_name(_getFileName(s.name))
		atex.set_atlas(tex)
		atex.set_region(s.region)
		err = ResourceSaver.save(ap, atex)
		if err != OK:
			return err
		else:
			print("Add: ", ap)

	return err

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var file = File.new()
	if file.open(source_file, File.READ) != OK:
		return FAILED

	var err = save_files(source_file, save_path, options)

	if err != OK:
		return err
