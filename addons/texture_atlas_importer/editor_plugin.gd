tool
extends EditorPlugin

var EditorImportPlugin = preload("res://addons/texture_atlas_importer/editor_import_plugin.gd")
var importer_plugin = null

func get_name():
	return "Texture Atlas Importer"

func _enter_tree():
	importer_plugin = EditorImportPlugin.new()
	add_import_plugin(importer_plugin)

func _exit_tree():
	remove_import_plugin(importer_plugin)
	importer_plugin = null
