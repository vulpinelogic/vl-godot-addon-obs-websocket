class_name VulpineLogicOBSWebSocketGetInputListRequest

extends VulpineLogicOBSWebSocketRequest


func _init(
		input_kind: String = "",
) -> void:
	if not input_kind.is_empty():
		request["inputKind"] = input_kind
	

func get_type() -> StringName:
	return "GetInputList"
