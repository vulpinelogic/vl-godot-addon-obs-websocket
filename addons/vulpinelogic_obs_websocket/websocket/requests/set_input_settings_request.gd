class_name VulpineLogicOBSWebSocketSetInputSettingsRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
		input: String,
		input_settings: Dictionary,
		overlay: bool = true
) -> void:
	setResourceRequestField("input", input)
	request["inputSettings"] = input_settings
	request["overlay"] = overlay
	

func get_type() -> StringName:
	return "SetInputSettings"
