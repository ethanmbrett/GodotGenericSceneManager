# Copyright (c) 2026 Ethan Brett
# Licensed under the MIT License. See LICENSE file in the project root for full license information

@tool
extends EditorPlugin

const SCENE_MANAGER_NAME = "SceneManager"

func _enable_plugin() -> void:
	# The autoload can be a scene or script file.
	add_autoload_singleton(SCENE_MANAGER_NAME, "res://addons/SimpleSceneManager/Singletons/SceneManager.tscn")


func _disable_plugin() -> void:
	# Remove autoloads here.
	remove_autoload_singleton(SCENE_MANAGER_NAME)
