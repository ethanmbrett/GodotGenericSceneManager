# Copyright (c) 2026 Ethan Brett
# Licensed under the MIT License. See LICENSE file in the project root for full license information

# Singleton scene manager
# Handles all loading operations
@tool
extends Node

# The list of loadable scenes
var SceneRegistry: Dictionary[String, String]
# The name of any scene currently being loaded. Set to be empty if none.
var CurrentLoadingScenePath: String = ""

@export_group("Initialization")
# List of scene names and file paths to initialize to the SceneManager
@export var InitializeScenes: Dictionary[String, String]

signal UpdateSceneLoading

signal UpdateResourceLoading

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AddScenesToRegistry(InitializeScenes)

# One of the bread-and-butter function of the manager. Starts loading a scene through the Resource Loader
func LoadScene(SceneName: String):
	if(SceneRegistry.keys().find(SceneName) == -1):
		push_error("Attempting to load unregistered scene with name: " + SceneName)
		get_tree().quit()
	CurrentLoadingScenePath = SceneRegistry[SceneName]
	# Check if we have Chunks to preload
	_StartResourceLoad(CurrentLoadingScenePath)
	var SceneStatus: float = _CheckResourceLoadStatus(CurrentLoadingScenePath)
	while(SceneStatus != 1.0 and SceneStatus != -1.0):
		UpdateSceneLoading.emit(SceneStatus, false)
		await  get_tree().process_frame
		SceneStatus = _CheckResourceLoadStatus(CurrentLoadingScenePath)
	UpdateSceneLoading.emit(SceneStatus, true)

# One of the bread-and-butter function of the manager. Finalizes the load operation and sets the loaded scene
# to be the new tree root.
func FinalizeSceneLoad():
	if(CurrentLoadingScenePath == ""):
		push_error("Attempting to finish scene load operation when no scene load is in progress!")
		get_tree().quit()
	if(ResourceLoader.load_threaded_get_status(CurrentLoadingScenePath) != ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED):
		push_error("Attempting to finalize scene load operation before the scene load operation is complete!")
		get_tree().quit()
	var LoadedScene: PackedScene = ResourceLoader.load_threaded_get(CurrentLoadingScenePath)
	get_tree().change_scene_to_packed.call_deferred(LoadedScene)
	CurrentLoadingScenePath = ""

# Function for loading individual resources asynchronously. Starts the load operation
func _StartResourceLoad(ResourcePath: String):
	if(!ResourceLoader.exists(ResourcePath)):
		push_error("Attempting load resource with invalid path: " + ResourcePath)
		get_tree().quit()
	ResourceLoader.load_threaded_request(ResourcePath)

# Function for loading individual resources asynchronously. Checks the status of a load operation
# Crashes and throws an error if the operation fails, else returns the progress of the operation
func _CheckResourceLoadStatus(ResourcePath: String) -> float:
	if(!ResourceLoader.exists(ResourcePath)):
		push_error("Attempting to check resource load operation with invalid path: " + ResourcePath)
		get_tree().quit()
	var LoaderProgress: Array
	var LoaderStatus: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(ResourcePath, LoaderProgress)
	if(LoaderStatus == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE):
		push_error("Attempting to check resource load operation without starting the load operation: " + ResourcePath)
		get_tree().quit()
	if(LoaderStatus == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED or len(LoaderProgress) < 1):
		push_error("Resource load failed: " + ResourcePath)
		get_tree().quit()
	if(LoaderStatus == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED):
		return 1.0
	return LoaderProgress[0]

# User side function for loading a resource and signaling when it is ready
func LoadResource(ResourcePath: String):
	_StartResourceLoad(ResourcePath)
	var ResStatus = _CheckResourceLoadStatus(ResourcePath)
	while(ResStatus != 1.0 and ResStatus != -1.0):
		await  get_tree().process_frame
		ResStatus = _CheckResourceLoadStatus(ResourcePath)
	if(ResStatus == -1.0):
		push_error("Failed to load resource: " + ResourcePath)
		get_tree().quit()
	UpdateResourceLoading.emit(ResourcePath)

# Function for loading individual resources asynchronously. Returns a loaded resource
# Crashes and throws an error if the operation fails, else returns resource
func FinalizeResourceLoad(ResourcePath: String) -> Resource:
	if(!ResourceLoader.exists(ResourcePath)):
		push_error("Attempting to finalize resource load operation with invalid path: " + ResourcePath)
		get_tree().quit()
	if(ResourceLoader.load_threaded_get_status(ResourcePath) == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE):
		push_error("Attempting to finalize resource load operation without starting the load operation: " + ResourcePath)
		get_tree().quit()
	if(ResourceLoader.load_threaded_get_status(ResourcePath) != ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED):
		push_error("Attempting to finalize resource load operation before the resource load operation is complete: " + ResourcePath)
		get_tree().quit()
	return ResourceLoader.load_threaded_get(ResourcePath)

# Adds a single scene to the registry. Mostly used as a helper
# function by the function that does this en mass.
func AddSceneToRegistry(SceneName: String, ScenePath: String):
	if(SceneRegistry.keys().find(SceneName) != -1):
		push_error("Attempting to add scene to registry with in-use name: " + SceneName)
		get_tree().quit()
	if(!ResourceLoader.exists(ScenePath, "PackedScene")):
		push_error("Attempting to add scene to registry with invalid scene path: " + ScenePath)
		get_tree().quit()
	# Due to a quirk of the exists function, we still have to make sure we're looking at a .tscn
	if(ScenePath.get_extension() != "tscn"):
		push_error("Attempting to add scene to registry with invalid scene path: " + ScenePath)
		get_tree().quit()
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
		get_tree().quit()
	if(!ResourceLoader.exists(ScenePath, "PackedScene")):
		push_error("Attempting to modify scene in registry to point to invalid scene path: " + ScenePath)
		get_tree().quit()
	# Due to a quirk of the exists function, we still have to make sure we're looking at a .tscn
	if(ScenePath.get_extension() != "tscn"):
		push_error("Attempting to modify scene in registry with invalid scene path: " + ScenePath)
		get_tree().quit()
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
		get_tree().quit()
	SceneRegistry.erase(SceneName)

# Same as the above for a group of scenes.
func RemoveScenesFromRegistry(SceneNames: Array[String]):
	for SceneName in SceneNames:
		RemoveSceneFromRegistry(SceneName)
