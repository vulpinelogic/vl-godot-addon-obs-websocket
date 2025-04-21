class_name VulpineLogicOBSWebSocketRemoveSceneItemRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
		scene: String,
		scene_item_id: int
) -> void:
	setResourceRequestField("scene", scene)
	request["sceneItemId"] = scene_item_id


func get_type() -> StringName:
	return "RemoveSceneItem"
