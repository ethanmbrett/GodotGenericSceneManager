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
# Whether the chunk list has been loaded into memory
var CanLoad: bool = false

@export_group("Initialization")
# List of scene names and file paths to initialize to the SceneManager
@export var InitializeScenes: Dictionary[String, String]

var ChunkLists: Dictionary[String, ResourceList]
var RequiredChunks: Array[String]
var LoadedChunks: Array[Resource]
signal UpdateChunkedLoading

signal UpdateResourceLoading

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AddScenesToRegistry(InitializeScenes)
	LoadedChunks.clear()
	RequiredChunks.clear()
	var SceneLoadChunks: ChunkList = ResourceLoader.load(SceneChunker.GlobalChunkListPath)
	# This loop just pulls the chunk lists into memory so we can access them at will
	for ChunkKey in SceneLoadChunks.SceneChunks.keys():
		var ChunkPath: String = SceneLoadChunks.SceneChunks[ChunkKey]
		_StartResourceLoad(ChunkPath);
		var ChunkStatus: float = _CheckResourceLoadStatus(ChunkPath)
		while(ChunkStatus != 1.0 and ChunkStatus != -1.0):
			await  get_tree().process_frame
			ChunkStatus = _CheckResourceLoadStatus(ChunkPath)
		ChunkLists[ChunkKey] = FinalizeResourceLoad(ChunkPath)

# One of the bread-and-butter function of the manager. Starts loading a scene through the Resource Loader
func StartSceneLoad(SceneName: String):
	if(SceneRegistry.keys().find(SceneName) == -1):
		push_error("Attempting to load unregistered scene with name: " + SceneName)
		get_tree().quit()
	CurrentLoadingScenePath = SceneRegistry[SceneName]
	# Check if we have Chunks to preload
	if(ChunkLists.keys().has(CurrentLoadingScenePath)):
		RequiredChunks = _CreateRequiredChunkList(CurrentLoadingScenePath)
	_LoadSceneChunked(SceneName)

# Recursively goes through all required scenes to amass a list of all necessary resources to load.
# I recommend not touching this function directly. It can very easily crash your game if
# improperly used.
func _CreateRequiredChunkList(ScenePath: String, ParentPath: String = "") -> Array[String]:
	var SceneChunkList: ResourceList = ChunkLists[ScenePath]
	if (ParentPath != ""):
		if(SceneChunkList.Resources.has(ParentPath) or SceneChunkList.Scenes.has(ParentPath)):
			push_error("Circular dependency detected between Scenes located at: " + ScenePath + " and " + ParentPath)
			get_tree().quit()
	var OutChunks: Array[String]
	OutChunks.append_array(SceneChunkList.Resources)
	for Scene in SceneChunkList.Scenes:
		if(!OutChunks.has(Scene)):
			OutChunks.append(Scene)
		if (!ChunkLists.keys().has(Scene)):
			continue
		OutChunks.append_array(_CreateRequiredChunkList(Scene, ScenePath))
	return OutChunks

func _LoadSceneChunked(SceneName: String):
	var SceneSize: float = FileAccess.get_size(CurrentLoadingScenePath)
	var TotalSize: float = SceneSize
	var ResourceSizes: Array[float]
	var LoadProgress: Array[float]
	# Grab the size of all required files
	for Res in RequiredChunks:
		var ResSize: float = FileAccess.get_size(Res)
		TotalSize += ResSize
		ResourceSizes.append(ResSize)
	# Load each resource. Individually
	for ResIndex in range(len(RequiredChunks)):
		var ResPath: String = RequiredChunks[ResIndex]
		LoadProgress.append(0.0)
		_StartResourceLoad(ResPath)
		var ResStatus: float = _CheckResourceLoadStatus(ResPath)
		while(ResStatus != 1.0 and ResStatus != -1.0):
			LoadProgress[ResIndex] = ResStatus * ResourceSizes[ResIndex] / TotalSize
			UpdateChunkedLoading.emit(LoadProgress, false)
			await  get_tree().process_frame
			ResStatus = _CheckResourceLoadStatus(ResPath)
		LoadedChunks.append(FinalizeResourceLoad(ResPath))
	LoadProgress.append(0.0)
	var SceneIndex = len(LoadProgress) - 1
	_StartResourceLoad(CurrentLoadingScenePath)
	var SceneStatus: float = _CheckResourceLoadStatus(CurrentLoadingScenePath)
	while(SceneStatus != 1.0 and SceneStatus != -1.0):
		LoadProgress[SceneIndex] = SceneStatus * SceneSize / TotalSize
		UpdateChunkedLoading.emit(LoadProgress, false)
		await  get_tree().process_frame
		SceneStatus = _CheckResourceLoadStatus(CurrentLoadingScenePath)
	UpdateChunkedLoading.emit(LoadProgress, true)

# One of the bread-and-butter function of the manager. Finalizes the load operation and sets the loaded scene
# to be the new tree root.
func FinalizeChunkedSceneLoad():
	if(CurrentLoadingScenePath == ""):
		push_error("Attempting to finish scene load operation when no scene load is in progress!")
		get_tree().quit()
	if(ResourceLoader.load_threaded_get_status(CurrentLoadingScenePath) != ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED):
		push_error("Attempting to finalize scene load operation before the scene load operation is complete!")
		return
	var LoadedScene: PackedScene = ResourceLoader.load_threaded_get(CurrentLoadingScenePath)
	get_tree().change_scene_to_packed.call_deferred(LoadedScene)
	CurrentLoadingScenePath = ""
	RequiredChunks.clear()
	LoadedChunks.clear()

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
	UpdateChunkedLoading.emit(ResourcePath)

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
		return null
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
