class_name VulpineLogicOBSWebSocketGetSceneItemIdRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
		scene: String,
		source_name: String,
		search_offset: int = -1
) -> void:
	setResourceRequestField("scene", scene)
	
	if is_uuid(source_name):
		push_error("Expected a resource name but received uuid %s" % source_name)
	
	request["sourceName"] = source_name
	
	if search_offset >= 0:
		request["searchOffset"] = search_offset
	

func get_type() -> StringName:
	return "GetSceneItemId"
