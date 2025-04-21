class_name VulpineLogicOBSWebSocketSetSceneItemEnabledRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
		scene: String,
		scene_item_id: int,
		scene_item_enabled: bool = true
) -> void:
	setResourceRequestField("scene", scene)
	request["sceneItemId"] = scene_item_id
	request["sceneItemEnabled"] = scene_item_enabled


func get_type() -> StringName:
	return "SetSceneItemEnabled"
