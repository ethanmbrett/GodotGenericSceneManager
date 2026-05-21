# Helper node spawned in when the first scene is loaded
# Sets up the scene manager

extends Node
class_name SceneManagerInitializer

@export_group("Initialization")
# List of scene names and files to send to the SceneManager
# Modify in the default version scene as necessary
@export var InitializeScenes: Dictionary[String, PackedScene]
@export var StartScene: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneManager.AddScenesToRegistry(InitializeScenes)
	SceneManager.LoadSceneFromRegistry(StartScene)
