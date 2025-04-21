class_name VulpineLogicOBSWebSocketGetSceneItemListRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
		scene: String
) -> void:
	set_resource_request_field("scene", scene)


func get_type() -> StringName:
	return "GetSceneItemList"
