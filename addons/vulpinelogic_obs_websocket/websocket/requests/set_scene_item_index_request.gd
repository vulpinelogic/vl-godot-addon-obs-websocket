class_name VulpineLogicOBSWebSocketSetSceneItemIndexRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
		scene: String,
		scene_item_id: int,
		scene_item_index: int
) -> void:
	setResourceRequestField("scene", scene)
	request["sceneItemId"] = scene_item_id
	request["sceneItemIndex"] = scene_item_index
	

func get_type() -> StringName:
	return "SetSceneItemIndex"
