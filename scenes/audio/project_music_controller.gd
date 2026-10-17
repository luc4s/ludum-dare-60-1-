extends "res://addons/maaacks_music_controller/base/scripts/music_controller.gd"
## Preserve scene music without cloning controller-owned players on shutdown.


func _on_removed_music_player(node: Node) -> void:
	# These players already survive scene changes; their removal is intentional.
	if node.get_parent() == self:
		return
	super._on_removed_music_player(node)
