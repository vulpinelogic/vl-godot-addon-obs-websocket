class_name VulpineLogicOBSWebSocketRequest

extends RefCounted

const UUID_PREFIX = &"uuid://"
const NAME_PREFIX = &"name://"

signal responded(response: Dictionary)

var request: Dictionary[StringName, Variant] = {}

var response: Dictionary = {}:
	set(value):
		response = _transform_response(value)
		responded.emit(response)


static func camel_case_dictionary(dict: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	
	for key in dict:
		var value = dict[key]
		
		if key is String or key is StringName:
			var result_key: String = key.to_camel_case()
	
			if value is Array:
				var result_value = []
				result[result_key] = result_value
				
				for item in value:
					result_value.append(
							camel_case_dictionary(item)
							if item is Dictionary
							else item
					)
			else:
				result[result_key] = (camel_case_dictionary(value)
						if value is Dictionary
						else value
				)
		else:
			result[key] = value
	
	return result


static func is_uuid(value: String) -> bool:
	return value.begins_with(UUID_PREFIX)


static func name_to_string(value: String) -> String:
	if value.begins_with(NAME_PREFIX):
		return value.substr(NAME_PREFIX.length())
	else:
		return value


static func snake_case_dictionary(dict: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	
	for key in dict:
		var value = dict[key]
		
		if key is String or key is StringName:
			var result_key: String = key.to_snake_case()
	
			if value is Array:
				var result_value = []
				result[result_key] = result_value
				
				for item in value:
					result_value.append(
							snake_case_dictionary(item)
							if item is Dictionary
							else item
					)
			else:
				result[result_key] = (snake_case_dictionary(value)
						if value is Dictionary
						else value
				)
		else:
			result[key] = value
	
	return result


static func string_to_uuid(value: String) -> String:
	if not value.is_empty() and not value.begins_with(UUID_PREFIX):
		return "uuid://%s" % value
	else:
		return value


static func uuid_to_string(value: String) -> String:
	if value.begins_with(UUID_PREFIX):
		return value.substr(UUID_PREFIX.length())
	else:
		return value


func get_type() -> StringName:
	return &""


func set_resource_request_field(name: String, resource: String) -> void:
	if is_uuid(resource):
		request["%sUuid" % name] = uuid_to_string(resource)
	else:
		request["%sName" % name] = name_to_string(resource)


func _transform_response(raw_response: Dictionary) -> Variant:
	var xformed_response = snake_case_dictionary(raw_response)
	xformed_response.ok = xformed_response.request_status.result
	return xformed_response
