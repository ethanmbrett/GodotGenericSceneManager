# Helper class to get around Godot not supported nested collections
extends Resource
class_name ResourceList

@export var Resources: Array[String] = []
@export var Scenes: Array[String] = []
