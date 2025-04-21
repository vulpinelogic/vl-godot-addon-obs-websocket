class_name VulpineLogicOBSWebSocketCreateSceneItemRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
	scene: String,
	source: String,
	scene_item_enabled: bool = true
):
	setResourceRequestField("scene", scene)
	setResourceRequestField("source", source)
	request["sceneItemEnabled"] = scene_item_enabled


func get_type() -> StringName:
	return "CreateSceneItem"
