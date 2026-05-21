# Copyright (c) 2026 Ethan Brett
# Licensed under the MIT License. See LICENSE file in the project root for full license information

# Singleton scene manager
# Handles all loading operations
extends Node

# The list of loadable scenes
var SceneRegistry: Dictionary[String, PackedScene]

# Bread-and-butter function of the manager. Loads a scene by name
# and makes it the new scene root.
func LoadSceneFromRegistry(SceneName: String):
	if(SceneRegistry.keys().find(SceneName) == -1):
		push_error("Attempting to load unregistered scene!")
		#get_tree().quit()
	get_tree().change_scene_to_packed.call_deferred(SceneRegistry[SceneName])

# Adds a single scene to the registry. Mostly used as a helper
# function by the function that does this en mass.
func AddSceneToRegistry(SceneName: String, SceneFile: PackedScene):
	if(SceneRegistry.keys().find(SceneName) != -1):
		push_error("Attempting to add scene to registry with an in-use key!")
		return
	SceneRegistry[SceneName] = SceneFile
	print(SceneRegistry)

# Adds a dictionary of scenes to the registry. This will mostly
# be used by the initializer.
func AddScenesToRegistry(Scenes: Dictionary[String, PackedScene]):
	for SceneName in Scenes.keys():
		AddSceneToRegistry(SceneName, Scenes[SceneName])

# Doubt that this will be necessary, but included for the sake of
# completeness. Redirects a scene name in the registry to point
# at a new PackedScene.
func ModifySceneInRegistry(SceneName: String, SceneFile: PackedScene):
	if(SceneRegistry.keys().find(SceneName) == -1):
		push_error("Attempting to modify unregistered scene!")
		return
	SceneRegistry[SceneName] = SceneFile

# Same as the above for a group of scenes.
func ModifyScenesInRegistry(Scenes: Dictionary[String, PackedScene]):
	for SceneName in Scenes.keys():
		ModifySceneInRegistry(SceneName, Scenes[SceneName])

# Doubt that this will be necessary, but included for the sake of
# completeness. Removes a scene from the registry
func RemoveSceneFromRegistry(SceneName: String):
	if(SceneRegistry.keys().find(SceneName) == -1):
		push_error("Attempting to remove unregistered scene!")
		return
	SceneRegistry.erase(SceneName)

# Same as the above for a group of scenes.
func RemoveScenesFromRegistry(SceneNames: Array[String]):
	for SceneName in SceneNames:
		RemoveSceneFromRegistry(SceneName)
