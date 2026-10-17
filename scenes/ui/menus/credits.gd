@tool
extends "res://addons/maaacks_game_template/base/nodes/labels/credits_label.gd"


func load_file(file_path: String) -> String:
	# Exports can omit Markdown files. Keep the scene's saved text in that case.
	if not FileAccess.file_exists(file_path):
		return ""
	return super.load_file(file_path)
