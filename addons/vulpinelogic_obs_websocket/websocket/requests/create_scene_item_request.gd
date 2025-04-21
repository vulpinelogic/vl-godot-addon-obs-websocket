class_name VulpineLogicOBSWebSocketCreateSceneItemRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
	scene: String,
	source: String,
	scene_item_enabled: bool = true
):
	set_resource_request_field("scene", scene)
	set_resource_request_field("source", source)
	request["sceneItemEnabled"] = scene_item_enabled


func get_type() -> StringName:
	return "CreateSceneItem"
