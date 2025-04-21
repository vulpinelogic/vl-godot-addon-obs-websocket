class_name VulpineLogicOBSWebSocketGetSceneItemListRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
		scene: String
) -> void:
	setResourceRequestField("scene", scene)


func get_type() -> StringName:
	return "GetSceneItemList"
