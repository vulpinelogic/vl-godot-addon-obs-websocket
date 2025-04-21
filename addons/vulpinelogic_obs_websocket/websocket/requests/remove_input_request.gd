class_name VulpineLogicOBSWebSocketRemoveInputRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
		input: String,
) -> void:
	set_resource_request_field("input", input)


func get_type() -> StringName:
	return "RemoveInput"
