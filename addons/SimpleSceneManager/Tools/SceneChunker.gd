@tool
extends Node
class_name SceneChunker

const FILEPATH = "res://addons/SimpleSceneManager/Resources/LoadChunkLists/"
const GlobalChunkListPath = "res://addons/SimpleSceneManager/Resources/GlobalChunkList.tres"

# Editor button for chunking a scene
@export_tool_button("Chunk Scene") var ChunkSceneButton = ChunkScene
@export_tool_button("De-Chunk Scene") var DeChunkSceneButton = DeChunkScene

# Gathers a list of all resources used in a scene and adds them to a registry of items
# to load before that scene can be loaded by the SceneManager
func ChunkScene():
	var GlobalChunkList: ChunkList = load(GlobalChunkListPath)
	var Parent: Node = get_parent()
	var ScenePath: String = Parent.scene_file_path
	var Chunks: ResourceList = ResourceList.new()
	# Get all nodes in the scene
	var Scenes: Array[Node]
	Scenes.append(Parent)
	Scenes.append_array(Parent.find_children("*"))
	# for each of them, gather a list of their resource fields
	for Scene in Scenes:
		if Scene == self:
			continue
		if(!Scene.scene_file_path == "" and Scene != Parent):
			Chunks.Scenes.append(Scene.scene_file_path)
		for PropertyData in Scene.get_property_list():
			if (Scene.get(PropertyData["name"]) is not Resource):
				continue
			var ResourceProperty: Resource = Scene.get(PropertyData["name"])
			if (ResourceProperty.resource_path.contains("::")):
				continue
			if (Chunks.Resources.has(ResourceProperty.resource_path)):
				continue
			Chunks.Resources.append(ResourceProperty.resource_path)
	var ResourcePath: String = FILEPATH + "ChunkList_" + Parent.name + ".tres"
	ResourceSaver.save(Chunks, ResourcePath)
	GlobalChunkList.SceneChunks[ScenePath] = ResourcePath

# Breaks the referene in the Global Chunk List to this scene
# Use if you no longer want this scene to use chunked loading
func DeChunkScene():
	var Parent: Node = get_parent()
	var GlobalChunkList: ChunkList = load(GlobalChunkListPath)
	GlobalChunkList.SceneChunks.erase(Parent.scene_file_path)
