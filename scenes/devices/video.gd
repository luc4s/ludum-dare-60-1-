class_name Video
extends Node3D
## Caméra de surveillance : rend la scène 3D dans une texture.
##
## Si [member source_camera] est renseignée, la vue copie cette caméra chaque
## frame. Sinon, le nœud Video sert lui-même de caméra : place-le et oriente-le
## comme une Camera3D.
## Récupère l'image avec [method get_texture] pour l'afficher sur un écran
## (material albedo, TextureRect, Sprite3D...).

## Écran sur lequel afficher le rendu. Optionnel.
## Le rendu est appliqué en albedo d'un StandardMaterial3D en
## [member GeometryInstance3D.material_override] (créé si absent).
@export var screen: GeometryInstance3D:
	set(value):
		screen = value
		_apply_to_screen()

## Caméra 3D à suivre. Optionnelle.
@export var source_camera: Camera3D:
	set(value):
		source_camera = value
		_sync_camera()

## Résolution du rendu.
@export var resolution := Vector2i(320, 240):
	set(value):
		resolution = value
		if _viewport:
			_viewport.size = resolution

## Mettre à jour l'image chaque frame. Désactiver pour un rendu figé.
@export var live := true:
	set(value):
		live = value
		if _viewport:
			_viewport.render_target_update_mode = (
				SubViewport.UPDATE_ALWAYS if live else SubViewport.UPDATE_ONCE
			)

@onready var _viewport: SubViewport = $SubViewport
@onready var _camera: Camera3D = $SubViewport/Camera3D


func _ready() -> void:
	_viewport.size = resolution
	_viewport.own_world_3d = false
	_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if live else SubViewport.UPDATE_ONCE
	)
	_camera.current = true
	_sync_camera()
	_apply_to_screen()


func _process(_delta: float) -> void:
	_sync_camera()


## Texture contenant le rendu. Reste valide tant que le nœud est dans l'arbre.
func get_texture() -> ViewportTexture:
	return _viewport.get_texture()


## Force un nouveau rendu (utile quand [member live] est désactivé).
func capture() -> void:
	_sync_camera()
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _apply_to_screen() -> void:
	if not screen or not _viewport:
		return
	var mat := screen.material_override as StandardMaterial3D
	if not mat:
		mat = StandardMaterial3D.new()
		screen.material_override = mat
	mat.albedo_texture = get_texture()


func _sync_camera() -> void:
	if not _camera:
		return
	if source_camera:
		_camera.global_transform = source_camera.global_transform
		_camera.projection = source_camera.projection
		_camera.fov = source_camera.fov
		_camera.size = source_camera.size
		_camera.near = source_camera.near
		_camera.far = source_camera.far
		_camera.cull_mask = source_camera.cull_mask
		_camera.environment = source_camera.environment
		_camera.attributes = source_camera.attributes
	else:
		_camera.global_transform = global_transform
