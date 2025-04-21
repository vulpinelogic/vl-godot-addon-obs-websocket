class_name VulpineLogicOBSWebSocketCreateInputRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
	scene: String,
	input_name: String,
	input_kind: String,
	input_settings: Dictionary = {},
	scene_item_enabled: bool = true
):
	setResourceRequestField("scene", scene)
	request["inputName"] = input_name
	request["inputKind"] = input_kind
	request["sceneItemEnabled"] = scene_item_enabled
	
	if not input_settings.is_empty():
		request["inputSettings"] = input_settings


func _transform_response(raw_response: Dictionary) -> Dictionary:
	var xformed_response = super(raw_response)
	
	if xformed_response.ok:
		var response_data = xformed_response.response_data
		response_data.input_uuid = "uuid://%s" % response_data.input_uuid
		
	return xformed_response
	

func get_type() -> StringName:
	return "CreateInput"
