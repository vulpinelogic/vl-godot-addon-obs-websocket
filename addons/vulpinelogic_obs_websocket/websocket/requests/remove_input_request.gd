class_name VulpineLogicOBSWebSocketRemoveInputRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
		input: String,
) -> void:
	setResourceRequestField("input", input)


func get_type() -> StringName:
	return "RemoveInput"
