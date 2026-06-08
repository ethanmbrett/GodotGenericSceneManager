# Copyright (c) 2026 Ethan Brett
# Licensed under the MIT License. See LICENSE file in the project root for full license information

# Singleton scene manager
# Handles all loading operations
extends Node

# The list of loadable scenes
var SceneRegistry: Dictionary[String, String]
# The name of any scene currently being loaded. Set to be empty if none.
var CurrentLoadingScenePath: String = ""
# Whether a scene has completed loading but hasn't been made scene root
var SceneReadyToInstance: bool = false

@export_group("Initialization")
# List of scene names and file paths to initialize to the SceneManager
@export var InitializeScenes: Dictionary[String, String]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AddScenesToRegistry(InitializeScenes)

# One of the bread-and-butter function of the manager. Starts loading a scene through the Resource Loader
func StartSceneLoad(SceneName: String):
	if(SceneRegistry.keys().find(SceneName) == -1):
		push_error("Attempting to load unregistered scene with name: " + SceneName)
		return
	CurrentLoadingScenePath = SceneRegistry[SceneName]
	ResourceLoader.load_threaded_request(CurrentLoadingScenePath)

# One of the bread-and-butter function of the manager. Checks the current status of a scene load operation
# Returns -1.0 if load is not in progress or fails
func CheckSceneLoadStatus() -> float:
	if(CurrentLoadingScenePath == ""):
		push_error("Attempting to check status of load operation when no load is in progress!")
		return -1.0
	var LoaderProgress: Array
	var LoaderStatus = ResourceLoader.load_threaded_get_status(CurrentLoadingScenePath, LoaderProgress)
	if (LoaderStatus == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED or len(LoaderProgress) < 1):
		push_error("Load operation failed!")
		return -1.0
	if (LoaderStatus == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED):
		push_error("Load operation failed due to invalid resource!")
		return -1.0
	if (LoaderStatus == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED):
		SceneReadyToInstance = true
	return LoaderProgress[0]

# One of the bread-and-butter function of the manager. Finalizes the load operation and sets the loaded scene
# to be the new tree root.
func FinalizeSceneLoad():
	if(CurrentLoadingScenePath == ""):
		push_error("Attempting to finish load operation when no load is in progress!")
		return
	if(!SceneReadyToInstance):
		push_error("Attempting to finalize load operation before load operation is complete!")
		return
	var LoadedScene: PackedScene = ResourceLoader.load_threaded_get(CurrentLoadingScenePath)
	CurrentLoadingScenePath = ""
	SceneReadyToInstance = false
	get_tree().change_scene_to_packed.call_deferred(LoadedScene)

# Adds a single scene to the registry. Mostly used as a helper
# function by the function that does this en mass.
func AddSceneToRegistry(SceneName: String, ScenePath: String):
	if(SceneRegistry.keys().find(SceneName) != -1):
		push_error("Attempting to add scene to registry with in-use name: " + SceneName)
		return
	if(!ResourceLoader.exists(ScenePath, "PackedScene")):
		push_error("Attempting to add scene to registry with invalid scene path: " + ScenePath)
		return
	# Due to a quirk of the exists function, we still have to make sure we're looking at a .tscn
	if(ScenePath.get_extension() != "tscn"):
		push_error("Attempting to add scene to registry with invalid scene path: " + ScenePath)
		return
	SceneRegistry[SceneName] = ScenePath
	print(SceneRegistry)

# Adds a dictionary of scenes to the registry. This will mostly
# be used by the initializer.
func AddScenesToRegistry(Scenes: Dictionary[String, String]):
	for SceneName in Scenes.keys():
		AddSceneToRegistry(SceneName, Scenes[SceneName])

# Doubt that this will be necessary, but included for the sake of
# completeness. Redirects a scene name in the registry to point
# at a new PackedScene.
func ModifySceneInRegistry(SceneName: String, ScenePath: String):
	if(SceneRegistry.keys().find(SceneName) == -1):
		push_error("Attempting to modify unregistered scene with name: " + SceneName)
		return
	if(!ResourceLoader.exists(ScenePath, "PackedScene")):
		push_error("Attempting to modify scene in registry to point to invalid scene path: " + ScenePath)
		return
	# Due to a quirk of the exists function, we still have to make sure we're looking at a .tscn
	if(ScenePath.get_extension() != "tscn"):
		push_error("Attempting to modify scene in registry with invalid scene path: " + ScenePath)
		return
	SceneRegistry[SceneName] = ScenePath

# Same as the above for a group of scenes.
func ModifyScenesInRegistry(Scenes: Dictionary[String, String]):
	for SceneName in Scenes.keys():
		ModifySceneInRegistry(SceneName, Scenes[SceneName])

# Doubt that this will be necessary, but included for the sake of
# completeness. Removes a scene from the registry
func RemoveSceneFromRegistry(SceneName: String):
	if(SceneRegistry.keys().find(SceneName) == -1):
		push_error("Attempting to remove unregistered scene with name: " + SceneName)
		return
	SceneRegistry.erase(SceneName)

# Same as the above for a group of scenes.
func RemoveScenesFromRegistry(SceneNames: Array[String]):
	for SceneName in SceneNames:
		RemoveSceneFromRegistry(SceneName)
