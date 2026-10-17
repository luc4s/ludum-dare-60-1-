extends SceneTree
## Run with: godot --path . --max-fps 60 --script tests/menu_flow_smoke.gd
## A graphical display is required by the template's keyboard labels.

const OPENING := "res://scenes/main/opening.tscn"
const MENU := "res://scenes/ui/menus/main_menu.tscn"
const GAME := "res://scenes/main/game.tscn"
const INTRO_MUSIC := "res://assets/audio/music/MUS_Intro.ogg"
const MENU_MUSIC := "res://assets/audio/music/MUS_Menu.ogg"

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)


func _wait_until(predicate: Callable, description: String) -> bool:
	var deadline := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await process_frame
	_check(false, "Timed out: " + description)
	quit(1)
	return false


func _is_scene(path: String) -> bool:
	return is_instance_valid(current_scene) and current_scene.scene_file_path == path


func _has_playing_track(path: String) -> bool:
	for player in root.find_children("*", "AudioStreamPlayer", true, false):
		if player.playing and player.stream != null and player.stream.resource_path == path:
			return true
	return false


func _music_is_silent() -> bool:
	for player in root.find_children("*", "AudioStreamPlayer", true, false):
		if player.bus in [&"Music", &"_BlendMusic"] and player.playing and player.stream != null:
			return false
	return true


func _capture(filename: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():
		return
	for frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.save_png("res://builds/" + filename + ".png") == OK, "Capture " + filename)


func _cancel() -> void:
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This UI test requires a graphical display for keyboard labels and popup drawing.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var music: MusicController = root.get_node("ProjectMusicController")
	_check(music != null, "Maaack's music controller is autoloaded")
	_check(AudioServer.get_bus_send(music.blend_audio_bus_idx) == &"Music", "Music transitions route through the Music volume bus")
	_check(ProjectSettings.get_setting("application/run/main_scene") == OPENING, "F5 starts the opening")
	change_scene_to_file(OPENING)
	if not await _wait_until(func(): return _is_scene(OPENING), "opening scene"):
		return
	var opening := current_scene
	if not await _wait_until(func(): return opening.next_image_index == 1, "logo fade-in"):
		return
	_check(_has_playing_track(INTRO_MUSIC), "Intro music plays over the logos")
	_check(not music.music_stream_player.stream.loop, "Intro music plays once")
	_check(music.music_stream_player.get_playback_position() > 0.0, "Intro playback advances")
	var logo_container := opening.get_node("ImagesContainer")
	_check(logo_container.get_child_count() == 2, "Opening displays both logos")
	_check(logo_container.get_child(0).texture.resource_path.contains("godot_engine_logo"), "Godot logo appears first")
	await _capture("01_opening")
	if not await _wait_until(func(): return opening.next_image_index == 2, "second logo fade-in"):
		return
	_check(logo_container.get_child(1).texture.resource_path == "res://assets/intro_logo.png", "Custom intro logo appears second")
	_check(logo_container.get_child(1).modulate.a > 0.9, "Custom intro logo is visible")
	await _capture("01b_intro_logo")
	if not await _wait_until(func(): return _is_scene(MENU), "automatic transition to main menu"):
		return
	var menu := current_scene
	if not await _wait_until(func(): return _has_playing_track(MENU_MUSIC) and not _has_playing_track(INTRO_MUSIC), "intro crossfades into menu music"):
		return
	var menu_player := music.music_stream_player
	_check(menu_player.stream.loop, "Menu music loops")
	var menu_music_position := menu_player.get_playback_position()
	_check(menu.new_game_button.text == "Play" and menu.new_game_button.visible, "Main menu has Play")
	_check(menu.options_button.visible and menu.credits_button.visible, "Options and Credits are available")
	await _capture("02_main_menu")

	menu.options_button.pressed.emit()
	if not await _wait_until(func(): return is_instance_valid(menu.sub_menu) and is_instance_valid(menu.sub_menu.instance), "options window"):
		return
	var options_window = menu.sub_menu
	var tabs: TabContainer = options_window.instance
	_check(tabs.get_tab_count() == 3, "Options includes Audio, Video, and Controls")
	for index in range(tabs.get_tab_count()):
		tabs.current_tab = index
		await process_frame
		await process_frame
		_check(tabs.get_current_tab_control().is_visible_in_tree(), "Options tab opens: " + tabs.get_tab_title(index))
		await _capture("03_options_" + tabs.get_tab_title(index).to_lower())
	var controls = tabs.get_node("Controls").get_node("%InputActionsList")
	_check(controls.action_button_map.has("ui_accept:0") and controls.action_button_map.has("ui_cancel:0"), "Controls has accept and pause bindings")
	options_window.close_button.pressed.emit()
	if not await _wait_until(func(): return menu.sub_menu == null, "Back closes options"):
		return

	menu.credits_button.pressed.emit()
	if not await _wait_until(func(): return is_instance_valid(menu.sub_menu) and is_instance_valid(menu.sub_menu.instance), "credits window"):
		return
	var credits = menu.sub_menu.instance
	_check(credits.attribution_file_path == "res://ATTRIBUTION.md", "Credits reads the root attribution file")
	var attribution := FileAccess.get_file_as_string("res://ATTRIBUTION.md")
	for line in attribution.split("\n"):
		var plain_line := line.strip_edges()
		if plain_line.is_empty() or plain_line.begins_with("#") or plain_line.begins_with("[") or plain_line == "...":
			continue
		_check(plain_line in credits.get_parsed_text(), "Credits includes: " + plain_line)
	_check("[url=https://godotengine.org/]" in credits.text, "Credits preserves Markdown links")
	var displayed_credits: String = credits.text
	credits.set_file_path("res://builds/missing_attribution_for_smoke_test.md")
	_check(credits.text == displayed_credits, "Credits keeps its saved text when Markdown is absent")
	credits.set_file_path("res://ATTRIBUTION.md")
	await _capture("04_credits")
	menu.sub_menu.close_button.pressed.emit()
	if not await _wait_until(func(): return menu.sub_menu == null, "Back closes credits"):
		return
	_check(music.music_stream_player == menu_player and menu_player.playing, "Options and Credits preserve the menu music player")
	_check(menu_player.get_playback_position() > menu_music_position, "Music continues while menu windows are open")

	menu.exit_button.pressed.emit()
	_check(menu.exit_confirmation.visible, "Exit asks for confirmation")
	menu.exit_confirmation.close()
	if not await _wait_until(func(): return not menu.exit_confirmation.visible, "cancel exit"):
		return
	menu.new_game_button.pressed.emit()
	if not await _wait_until(func(): return _is_scene(GAME), "Play loads the 3D game"):
		return
	_check(current_scene is Node3D, "Game is a 3D scene")
	_check(current_scene.get_node("BaseLevel").get_child_count() == 0, "Base level has no gameplay objects")
	_check(root.get_camera_3d() != null, "3D scene has an active camera")
	if not await _wait_until(_music_is_silent, "Play fades menu music to silence"):
		return
	_check(music.music_stream_player.stream == null, "Empty game requests silence with its music player")
	await _capture("05_empty_game")
	var controller = current_scene.get_node("PauseMenuController")
	if not await _wait_until(func(): return is_instance_valid(controller.pause_menu) and controller.pause_menu.is_inside_tree(), "pause menu ready"):
		return
	await _cancel()
	if not await _wait_until(func(): return paused, "Escape pauses the game"):
		return
	var pause_menu = controller.pause_menu
	_check(pause_menu.visible, "Pause menu is visible")
	await _capture("06_pause")
	pause_menu.options_button.pressed.emit()
	if not await _wait_until(func(): return is_instance_valid(pause_menu.open_window) and pause_menu.open_window.is_inside_tree(), "pause options"):
		return
	_check(paused and pause_menu.open_window.can_process(), "Options works while paused")
	pause_menu.open_window.close_button.pressed.emit()
	if not await _wait_until(func(): return pause_menu.open_window == null, "close pause options"):
		return
	_check(paused, "Closing pause options keeps the game paused")
	pause_menu.close_button.pressed.emit()
	if not await _wait_until(func(): return not paused and not pause_menu.visible and not pause_menu.is_reparenting, "Resume unpauses"):
		return
	await _cancel()
	if not await _wait_until(func(): return paused, "pause again"):
		return
	var previous_game_id := current_scene.get_instance_id()
	pause_menu._on_restart_button_pressed()
	await process_frame
	pause_menu.restart_confirmation.confirm_button.pressed.emit()
	if not await _wait_until(func(): return _is_scene(GAME) and current_scene.get_instance_id() != previous_game_id, "restart creates a fresh game scene"):
		return
	_check(not paused, "Restart unpauses the new game")
	controller = current_scene.get_node("PauseMenuController")
	if not await _wait_until(func(): return is_instance_valid(controller.pause_menu) and controller.pause_menu.is_inside_tree(), "new pause menu ready"):
		return
	await _cancel()
	if not await _wait_until(func(): return paused, "pause after restart"):
		return
	pause_menu = controller.pause_menu
	pause_menu.main_menu_button.pressed.emit()
	await process_frame
	pause_menu.main_menu_confirmation.confirm_button.pressed.emit()
	if not await _wait_until(func(): return _is_scene(MENU), "return to main menu"):
		return
	_check(not paused, "Returning to the main menu clears pause state")
	_check(_has_playing_track(MENU_MUSIC), "Returning to the main menu restarts its music")
	current_scene.new_game_button.pressed.emit()
	if not await _wait_until(func(): return _is_scene(GAME), "Play works after returning"):
		return
	_check(not paused, "Second play session runs unpaused")
	if not await _wait_until(_music_is_silent, "rapid menu-to-game transition finishes fading"):
		return
	# Exercise the documented API and pause behavior for future gameplay tracks.
	music.play_stream(load(MENU_MUSIC))
	await create_timer(music.fade_in_duration + 0.1).timeout
	var gameplay_music_position := music.music_stream_player.get_playback_position()
	paused = true
	await create_timer(0.2).timeout
	_check(music.music_stream_player.playing and music.music_stream_player.get_playback_position() > gameplay_music_position, "Music keeps playing while the game is paused")
	music.play_stream(null)
	if not await _wait_until(_music_is_silent, "scripted fade to silence works while paused"):
		return
	paused = false
	# Let deferred pause-menu creation complete before ending the test.
	for frame in range(5):
		await process_frame
	print("Menu flow smoke test: ", failures, " failure(s)")
	quit(1 if failures else 0)
