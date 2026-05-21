## Copyright notice
Copyright (c) 2026 Ethan Brett  
Licensed under the MIT License. See LICENSE file in the project root for full license information

# GodotGenericSceneManager
Simple scene manager system for Godot projects.

## Use Cases
This scene manager is largely meant to avoid the project corruption that tends to occur when scenes directly reference
each other in Godot. This plugin doesn't handle large-scale, continuous loading (such as would require a loading screen),
but will possibly be expanded to allow for it later down the road.

## Installation
Drag the addons folder from this plugin into the resources folder for your project. Go into the plugins tab of your project settings and enable this plugin. Go to the general tab of your project settings and look for "Application/Run" in the hierarchy. In this tab's "Main Scene" field, select "res://addons/SimpleSceneManager/Initializer/SceneManagerInitializer.tscn"

Now, open SceneManagerInitializer.tscn for editing. Under Initialization/Initialize_Scenes, add every scene you want to be loadable from the beginning of play as String/Packed Scene pairs. Under Initialization/Start_Scene, type in the key of the first scene you would like to be loaded, typically a main menu scene.

## Loading Scenes
To load a scene from code, use the following function signature: "SceneManager.LoadSceneFromRegistry("MySceneName")"

## Other Usage
The SceneManager autoload contains functions for Adding and Removing scenes from the registry at runtime, as well as changing
the packed scene that a key references. These function are available both with both single-scene and mass variants. Their signatures can be found in "res://addons/SimpleSceneManager/Singletons/SceneManager.gd"