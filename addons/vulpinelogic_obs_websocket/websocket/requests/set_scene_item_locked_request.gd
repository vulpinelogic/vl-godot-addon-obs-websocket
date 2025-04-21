class_name VulpineLogicOBSWebSocketSetSceneItemLockedRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
		scene: String,
		scene_item_id: int,
		scene_item_locked: bool = true 
) -> void:
	setResourceRequestField("scene", scene)
	request["sceneItemId"] = scene_item_id
	request["sceneItemLocked"] = scene_item_locked
	

func get_type() -> StringName:
	return "SetSceneItemLocked"
