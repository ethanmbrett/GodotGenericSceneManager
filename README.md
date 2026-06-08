## Copyright notice
Copyright (c) 2026 Ethan Brett  
Licensed under the MIT License. See LICENSE file in the project root for full license information

# GodotGenericSceneManager
Simple scene manager system for Godot projects.

## Use Cases
This scene manager is largely meant to avoid the project corruption that tends to occur when scenes directly reference
each other in Godot. This plugin doesn't yet handle large-scale, continuous loading, such as would require a loading screen.

## Installation
Drag the addons folder from this plugin into the resources folder for your project. Go into the plugins tab of your project settings and enable this plugin. Open the SceneManager scene file in the "Res://addons/Singletons" folder and add all scenes you would like to be immediately accessible to the scene loader to its "Initialize Scenes" field. Any of these scenes can now be loaded through the SceneManager.

## Loading Scenes
To load a scene from code, use the following function signature: "SceneManager.LoadSceneFromRegistry("MySceneName")"

## Other Usage
The SceneManager autoload contains functions for Adding and Removing scenes from the registry at runtime, as well as changing
the packed scene that a key references. These function are available both with both single-scene and mass variants. Their signatures can be found in "res://addons/SimpleSceneManager/Singletons/SceneManager.gd"

## Roadmap
This plugin is not yet feature-complete, and will be expanded to allow to include new features, following this roadmap:  

v0.2: Remove need for the initializer -- Current Version  
v0.3: Add asynchronous loading  
v0.4: Add resource loading  
v0.5: Add chunked scene loading. Feature-complete, beta release  
v1.0: Testing, cleanup, and documentation. Full release  