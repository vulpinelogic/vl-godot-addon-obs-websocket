class_name VulpineLogicOBSWebSocketCreateSceneRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
	scene_name: String,
):
	request["sceneName"] = scene_name


func _transform_response(raw_response: Dictionary) -> Dictionary:
	var xformed_response = super(raw_response)
	
	if xformed_response.ok:
		var response_data = xformed_response.response_data
		response_data.scene_uuid = "uuid://%s" % response_data.scene_uuid
		
	return xformed_response
	

func get_type() -> StringName:
	return "CreateScene"
