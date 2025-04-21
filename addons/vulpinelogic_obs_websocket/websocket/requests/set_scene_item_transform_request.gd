class_name VulpineLogicOBSWebSocketSetSceneItemTransformRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
		scene: String,
		scene_item_id: int,
		scene_item_transform: Dictionary
) -> void:
	setResourceRequestField("scene", scene)
	request["sceneItemId"] = scene_item_id
	request["sceneItemTransform"] = camel_case_dictionary(scene_item_transform)
	

func get_type() -> StringName:
	return "SetSceneItemTransform"
