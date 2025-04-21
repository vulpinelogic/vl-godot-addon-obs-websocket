class_name VulpineLogicOBSWebSocketGetInputPropertiesListPropertyItemsRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
		input: String,
		property_name: String
) -> void:
	set_resource_request_field("input", input)
	request["propertyName"] = property_name


func get_type() -> StringName:
	return "GetInputPropertiesListPropertyItems"
