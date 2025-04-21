@icon("res://addons/vulpinelogic_obs_websocket/icon.png")
class_name VulpineLogicOBSWebSocket

extends Node

signal closed
signal connected
signal connection_failed(error: int)
signal current_profile_change_started(profile_name: String)
signal current_profile_changed(profile_name: String)
signal current_preview_scene_changed(scene_name: String, scene_uuid: String)
signal current_program_scene_changed(scene_name: String, scene_uuid: String)
signal current_scene_collection_change_started(scene_collection_name: String)
signal current_scene_collection_changed(scene_collection_name: String)
signal current_scene_transition_changed(transition_name: String, transition_uuid: String)
signal current_scene_transition_duration_changed(transition_duration: float)
signal custom_event_received(event: Dictionary)
signal exit_started
signal identified(event: Dictionary)
signal input_active_state_changed(input_name: String, input_uuid: String, video_active: bool)
signal input_audio_balance_changed(input_name: String, input_uuid: String, input_audio_balance: float)
signal input_audio_sync_offset_changed(input_name: String, input_uuid: String, input_audio_sync_offset: float)
signal input_audio_tracks_changed(input_name: String, input_uuid: String, input_audio_tracks: Dictionary)
signal input_audio_monitor_type_changed(input_name: String, input_uuid: String, monitor_type: String)
signal input_created(event: Dictionary)
signal input_mute_state_changed(input_name: String, input_uuid: String, input_muted: bool)
signal input_name_changed(input_uuid: String, old_input_name: String, input_name: String)
signal input_removed(input_name: String, input_uuid: String)
signal input_settings_changed(input_name: String, input_uuid: String, input_settings: Dictionary)
signal input_show_state_changed(input_name: String, input_uuid: String, video_showing: bool)
signal input_volume_changed(input_name: String, input_uuid: String, input_volume_mul: float, input_volume_db: float)
signal input_volume_meters_updated(inputs: Array)
signal media_input_action_triggered(input_name: String, input_uuid: String, media_action: String)
signal media_input_playback_ended(input_name: String, input_uuid: String)
signal media_input_playback_started(input_name: String, input_uuid: String)
signal profile_list_changed(profiles: Array)
signal record_file_changed(new_output_path: String)
signal record_state_changed(output_active: bool, output_state: String, output_path: String)
signal replay_buffer_saved(saved_replay_path: String)
signal replay_buffer_state_changed(output_active: bool, output_state: String)
signal scene_collection_list_changed(scene_collections: Array)
signal scene_created(scene_name: String, scene_uuid: String, is_group: bool)
signal scene_item_created(event: Dictionary)
signal scene_item_enable_state_changed(scene_name: String, scene_uuid: String, scene_item_id: int, scene_item_enabled: bool)
signal scene_item_list_reindexed(scene_name: String, scene_uuid: String, scene_items: Array)
signal scene_item_lock_state_changed(scene_name: String, scene_uuid: String, scene_item_id: int, scene_item_locked: bool)
signal scene_item_removed(event: Dictionary)
signal scene_item_selected(scene_name: String, scene_uuid: String, scene_item_id: int)
signal scene_item_transform_changed(scene_name: String, scene_uuid: String, scene_item_id: int, scene_item_transform: Dictionary)
signal scene_list_changed(scenes: Array)
signal scene_name_changed(scene_uuid: String, old_scene_name: String, scene_name: String)
signal scene_removed(scene_name: String, scene_uuid: String, is_group: bool)
signal scene_transition_ended(transition_name: String, transition_uuid: String)
signal scene_transition_started(transition_name: String, transition_uuid: String)
signal scene_transition_video_ended(transition_name: String, transition_uuid: String)
signal screenshot_saved(saved_screenshot_path: String)
signal source_filter_created(event: Dictionary)
signal source_filter_enable_state_changed(source_name: String, filter_name: String, filter_enabled: bool)
signal source_filter_list_reindexed(source_name: String, filters: Array)
signal source_filter_name_changed(source_name: String, old_filter_name: String, filter_name: String)
signal source_filter_removed(source_name: String, filter_name: String)
signal source_filter_settings_changed(source_name: String, filter_name: String, filter_settings: Dictionary)
signal stream_state_changed(output_active: bool, output_state: String)
signal studio_mode_state_changed(studio_mode_enabled: bool)
signal vendor_event_received(vendor_name: String, event_type: String, event_data: Dictionary)
signal virtualcam_state_changed(output_active: bool, output_state: String)

const DEFAULT_HOST = "ws://127.0.0.1:4455"

@export var host: String = DEFAULT_HOST:
	get():
		return host if not host.is_empty() else DEFAULT_HOST
	set(value):
		host = value
		_handle_config_change()

@export_range(1, 60, 1.0, "hide_slider", "or_greater", "suffix:seconds")
var reconnect_delay: int = 1


var is_identified: bool:
	get():
		return _negotiated_rpc_version > 0


var password: String:
	set(value):
		password = value
		_handle_config_change()


var _websocket = WebSocketPeer.new()

var _last_ws_state: int
var _negotiated_rpc_version: int = 0
var _next_request_id: int = 1
var _pending_requests: Dictionary[String, VulpineLogicOBSWebSocketRequest] = {}
var _process_state: Callable = _process_state_closed


func _ready() -> void:
	_open()


func _process(_delta: float) -> void:
	_websocket.poll()
	_process_state.call(_websocket.get_ready_state())

	var packets = _websocket.get_available_packet_count()
	
	for packet_index in packets:
		var packet = _websocket.get_packet().get_string_from_utf8()
		var json = JSON.parse_string(packet)
		var op_code = json.op as int
		
		match op_code:
			0:
				_handle_hello(json.d)
			2:
				_handle_identified(json.d)
			5:
				_handle_event(json.d)
			7:
				_handle_request_response(json.d)
			_:
				print_debug(json)


func create_input(
		scene: String,
		input_name: String,
		input_kind: String,
		input_settings = {},
		scene_item_enabled = false
) -> Dictionary:
	var response = await request(
			VulpineLogicOBSWebSocketCreateInputRequest.new(
					scene,
					input_name,
					input_kind,
					input_settings,
					scene_item_enabled
			)
	)
	
	if not response.ok:
		return {}
		
	response.response_data.input_uuid = VulpineLogicOBSWebSocketRequest.string_to_uuid(response.response_data.input_uuid)
	return response.response_data


func create_scene(
		scene_name: String
) -> String:
	var response = await request(
			VulpineLogicOBSWebSocketCreateSceneRequest.new(scene_name)
	)
	
	if not response.ok:
		return ""
	
	return VulpineLogicOBSWebSocketRequest.string_to_uuid(
			response.response_data.get("scene_uuid", "")
	)


func create_scene_item(
		scene: String,
		source: String,
		scene_item_enabled = false
) -> int:
	var response = await request(
			VulpineLogicOBSWebSocketCreateSceneItemRequest.new(
					scene,
					source,
					scene_item_enabled
			)
	)
	
	if not response.ok:
		return -1
	
	return response.response_data.scene_item_id


func get_current_profile() -> String:
	var response = await request(
			VulpineLogicOBSWebSocketGetProfileListRequest.new()
	)
	
	if not response.ok:
		return ""
	
	return response.response_data.current_profile_name


func get_current_program_scene() -> Dictionary:
	var response = await request(
			VulpineLogicOBSWebSocketGetCurrentProgramSceneRequest.new()
	)
	
	if not response.ok:
		return {}
		
	response.response_data.current_program_scene_uuid = VulpineLogicOBSWebSocketRequest.string_to_uuid(response.response_data.current_program_scene_uuid)
	response.response_data.scene_uuid = VulpineLogicOBSWebSocketRequest.string_to_uuid(response.response_data.scene_uuid)
	return response.response_data


func get_current_program_scene_name() -> String:
	var scene = await get_current_program_scene()
	return scene.get("scene_name", "")


func get_current_program_scene_uuid() -> String:
	var scene = await get_current_program_scene()
	
	if scene.get("scene_uuid") == null:
		return ""
	
	return VulpineLogicOBSWebSocketRequest.string_to_uuid(scene.scene_uuid)


func get_current_scene_collection() -> String:
	var response = await request(
			VulpineLogicOBSWebSocketGetSceneCollectionListRequest.new()
	)
	
	if not response.ok:
		return ""
	
	return response.response_data.current_scene_collection_name


func get_input_properties_list_property_items(
		input: String,
		property_name: String
) -> Array[Dictionary]:
	var response = await request(
			VulpineLogicOBSWebSocketGetInputPropertiesListPropertyItemsRequest.new(
				input,
				property_name
			)
	)
	
	if not response.ok:
		return []
	
	var result = Array([], TYPE_DICTIONARY, "", null)
	
	for item in response.response_data.property_items:
		result.append(item)
	
	return result
	
	
func get_input_kind(input: String) -> String:
	var response = await request(
			VulpineLogicOBSWebSocketGetInputSettingsRequest.new(input)
	)
	
	if not response.ok:
		return ""
	
	return response.response_data.input_kind


func get_input_kind_list() -> Array[StringName]:
	var response = await request(
			VulpineLogicOBSWebSocketGetInputKindListRequest.new()
	)
	
	if not response.ok:
		return []
	
	return Array(response.response_data.input_kinds, TYPE_STRING_NAME, "", null)


func get_input_settings(input: String) -> Dictionary:
	var response = await request(
			VulpineLogicOBSWebSocketGetInputSettingsRequest.new(input)
	)
	
	if not response.ok:
		return {}
	
	return response.response_data.input_settings


func get_inputs(input_kind: String = "") -> Array:
	var response = await request(
			VulpineLogicOBSWebSocketGetInputListRequest.new(input_kind)
	)
	
	if not response.ok:
		return []
		
	for input in response.response_data.inputs:
		input.input_uuid = VulpineLogicOBSWebSocketRequest.string_to_uuid(input.input_uuid)
	
	return response.response_data.inputs


func get_profile_list() -> Array:
	var response = await request(
			VulpineLogicOBSWebSocketGetProfileListRequest.new()
	)
	
	if not response.ok:
		return []
	
	return response.response_data.profiles


func get_scene_collection_list() -> Array:
	var response = await request(
			VulpineLogicOBSWebSocketGetSceneCollectionListRequest.new()
	)
	
	if not response.ok:
		return []
	
	return response.response_data.scene_collections


func get_scene_list() -> Array:
	var response = await request(
			VulpineLogicOBSWebSocketGetSceneListRequest.new()
	)
	
	if not response.ok:
		return []
		
	for scene in response.response_data.scenes:
		scene.scene_uuid = VulpineLogicOBSWebSocketRequest.string_to_uuid(scene.scene_uuid)
	
	return response.response_data.scenes


func get_scene_item_list(scene: String) -> Array:
	var response = await request(
			VulpineLogicOBSWebSocketGetSceneItemListRequest.new(scene)
	)
	
	if not response.ok:
		return []
		
	return response.response_data.scene_items


func get_scene_item_id(
		scene: String,
		source_name: String
) -> int:
	var response = await request(
			VulpineLogicOBSWebSocketGetSceneItemIdRequest.new(
					scene,
					source_name
			)
	)
	
	if not response.ok:
		return -1
	
	return response.response_data.scene_item_id


func get_scene_item_transform(
		scene: String,
		scene_item_id: int
) -> Dictionary:
	var response = await request(
			VulpineLogicOBSWebSocketGetSceneItemTransformRequest.new(
					scene,
					scene_item_id
			)
	)

	if not response.ok:
		return {}
		
	return response.response_data.scene_item_transform
	

func get_video_settings() -> Dictionary:
	var response = await request(
			VulpineLogicOBSWebSocketGetVideoSettingsRequest.new()
	)
	
	if not response.ok:
		return {}
		
	var response_data = response.response_data as Dictionary
		
	response_data.merge({
		"base_size": Vector2i(
				response_data.get("base_width"),
				response_data.get("base_height")
		),
		"output_size": Vector2i(
				response_data.get("output_width"),
				response_data.get("output_height")
		),
	}, true)
	
	return response_data


func remove_input(input: String) -> bool:
	var response = await request(
			VulpineLogicOBSWebSocketRemoveInputRequest.new(input)
	)
	
	return response.ok


func remove_scene_item(scene: String, scene_item_index: int) -> bool:
	var response = await request(
			VulpineLogicOBSWebSocketRemoveSceneItemRequest.new(scene, scene_item_index)
	)
	
	return response.ok


func set_scene_item_enabled(
		scene: String,
		scene_item_id: int,
		scene_item_enabled: bool = true
) -> bool:
	var response = await request(
			VulpineLogicOBSWebSocketSetSceneItemEnabledRequest.new(
					scene,
					scene_item_id,
					scene_item_enabled
			)
	)

	return response.ok


func set_scene_item_index(
		scene: String,
		scene_item_id: int,
		scene_item_index: int
) -> bool:
	var response = await request(
			VulpineLogicOBSWebSocketSetSceneItemIndexRequest.new(
					scene,
					scene_item_id,
					scene_item_index
			)
	)

	return response.ok


func set_scene_item_locked(
		scene: String,
		scene_item_id: int,
		scene_item_locked: bool = true
) -> bool:
	var response = await request(
			VulpineLogicOBSWebSocketSetSceneItemLockedRequest.new(
					scene,
					scene_item_id,
					scene_item_locked
			)
	)

	return response.ok


func set_scene_item_transform(
		scene: String,
		scene_item_id: int,
		scene_item_transform: Dictionary
) -> bool:
	var response = await request(
			VulpineLogicOBSWebSocketSetSceneItemTransformRequest.new(
					scene,
					scene_item_id,
					scene_item_transform
			)
	)

	return response.ok


func set_input_settings(
		input_uuid: String,
		input_settings: Dictionary,
		overlay: bool = true
) -> bool:
	var response = await request(
			VulpineLogicOBSWebSocketSetInputSettingsRequest.new(
				input_uuid,
				input_settings,
				overlay
			)
	)
	
	return response.ok


func reidentify(
		event_subscriptions: int = EventSubscription.ALL,
) -> void:
	var message = {
		"op": 3,
		"d": {
			"eventSubscriptions": event_subscriptions
		}
	}
	
	_websocket.send_text(JSON.stringify(message))


func request(req: VulpineLogicOBSWebSocketRequest) -> Dictionary:
	var request_id = "%d" % _next_request_id
	_next_request_id += 1
	_pending_requests[request_id] = req
	
	var message = {
		"op": 6,
		"d": {
			"requestType": req.get_type(),
			"requestId": request_id,
		}
	}
	
	if not req.request.is_empty():
		message.d.requestData = req.request
	
	_websocket.send_text(JSON.stringify(message))
	return await req.responded


func _close() -> void:
	_websocket.close()


func _handle_config_change() -> void:
	if not password.is_empty():
		_open()
	else:
		_close()


func _handle_event(event: Dictionary) -> void:
	var event_data = event.get("eventData", {})
	
	match event.eventType:
		"CurrentProfileChanged":
			current_profile_changed.emit(event_data.get("profileName", ""))
		"CurrentProfileChanging":
			current_profile_change_started.emit(
					event_data.get("profileName", "")
			)
		"CurrentPreviewSceneChanged":
			current_preview_scene_changed.emit(
					event_data.get("sceneName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("sceneUuid", ""))
			)
		"CurrentProgramSceneChanged":
			current_program_scene_changed.emit(
					event_data.get("sceneName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("sceneUuid", ""))
			)
		"CurrentSceneCollectionChanging":
			current_scene_collection_change_started.emit(
					event_data.get("sceneCollectionName", "")
			)
		"CurrentSceneCollectionChanged":
			current_scene_collection_changed.emit(
					event_data.get("sceneCollectionName", "")
			)
		"CurrentSceneTransitionChanged":
			current_scene_transition_changed.emit(
					event_data.get("sceneName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("sceneUuid", ""))
			)
		"CurrentSceneTransitionDurationChanged":
			current_scene_transition_duration_changed.emit(
					event_data.get("transitionDuration", 0.0)
			)
		"CustomEvent":
			custom_event_received.emit(
					VulpineLogicOBSWebSocketRequest.snake_case_dictionary(event_data)
			)
		"ExitStarted":
			exit_started.emit()
		"InputActiveStateChanged":
			input_active_state_changed.emit(
					event_data.get("inputName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", "")),
					event_data.get("videoActive", false)
			)
		"InputAudioBalanceChanged":
			input_audio_balance_changed.emit(
					event_data.get("inputName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", "")),
					event_data.get("inputAudioBalance", 0.0)
			)
		"InputAudioSyncOffsetChanged":
			input_audio_sync_offset_changed.emit(
					event_data.get("inputName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", "")),
					event_data.get("inputAudioSyncOffset", 0.0)
			)
		"InputAudioTracksChanged":
			input_audio_tracks_changed.emit(
					event_data.get("inputName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", "")),
					event_data.get("inputAudioTracks", {})
			)
		"InputAudioMonitorTypeChanged":
			input_audio_monitor_type_changed.emit(
					event_data.get("inputName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", "")),
					event_data.get("monitorType", "")
			)
		"InputCreated":
			input_created.emit(
					VulpineLogicOBSWebSocketRequest.snake_case_dictionary(event_data)
			)
		"InputMuteStateChanged":
			input_mute_state_changed.emit(
					event_data.get("inputName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", "")),
					event_data.get("inputMuted", false)
			)
		"InputNameChanged":
			input_name_changed.emit(
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", "")),
					event_data.get("oldInputName", ""),
					event_data.get("inputName", ""),
			)
		"InputRemoved":
			input_removed.emit(
					event_data.get("inputName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", ""))
			)
		"InputSettingsChanged":
			input_settings_changed.emit(
					event_data.get("inputName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", "")),
					event_data.get("inputSettings", {}),
			)
		"InputShowStateChanged":
			input_show_state_changed.emit(
					event_data.get("inputName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", "")),
					event_data.get("videoShowing", false)
			)
		"InputVolumeChanged":
			input_volume_changed.emit(
					event_data.get("inputName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", "")),
					event_data.get("inputVolumeMul", 0.0),
					event_data.get("inputVolumeDb", 0.0),
			)
		"InputVolumeMetersUpdated":
			input_volume_meters_updated.emit(event_data.get("inputs", []))
		"MediaInputActionTriggered":
			media_input_action_triggered.emit(
					event_data.get("inputName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", "")),
					# TODO: Emit enum instead of string
					event_data.get("mediaAction", ""),
			)
		"MediaInputPlaybackEnded":
			media_input_playback_ended.emit(
					event_data.get("inputName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", "")),
			)
		"MediaInputPlaybackStarted":
			media_input_playback_started.emit(
					event_data.get("inputName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("inputUuid", "")),
			)
		"ProfileListChanged":
			profile_list_changed.emit(event_data.get("profiles", []))
		"RecordFileChanged":
			record_file_changed.emit(event_data.get("newOutputPath", ""))
		"RecordStateChanged":
			record_state_changed.emit(
					event_data.get("output_active", false),
					event_data.get("output_state", ""),
					event_data.get("output_path", ""),
			)
		"ReplayBufferSaved":
			replay_buffer_saved.emit(event_data.get("savedReplayPath", ""))
		"ReplayBufferStateChanged":
			replay_buffer_state_changed.emit(
					event_data.get("output_active", false),
					event_data.get("output_state", ""),
			)
		"SceneCollectionListChanged":
			scene_collection_list_changed.emit(
					event_data.get("sceneCollections", [])
			)
		"SceneCreated":
			scene_created.emit(
					event_data.get("sceneName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("sceneUuid", "")),
					event_data.get("is_group", false)
			)
		"SceneItemCreated":
			scene_item_created.emit(
					VulpineLogicOBSWebSocketRequest.snake_case_dictionary(event_data)
			)
		"SceneItemEnableStateChanged":
			scene_item_enable_state_changed.emit(
					event_data.get("sceneName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("sceneUuid", "")),
					event_data.get("sceneItemId", 0),
					event_data.get("sceneItemEnabled", false),
			)
		"SceneItemListReindexed":
			scene_item_list_reindexed.emit(
					event_data.get("sceneName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("sceneUuid", "")),
					event_data.get("sceneItems", []),
			)
		"SceneItemLockStateChanged":
			scene_item_lock_state_changed.emit(
					event_data.get("sceneName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("sceneUuid", "")),
					event_data.get("sceneItemId", 0),
					event_data.get("sceneItemLocked", false),
			)
		"SceneItemRemoved":
			scene_item_removed.emit(
					VulpineLogicOBSWebSocketRequest.snake_case_dictionary(event_data)
			)
		"SceneItemSelected":
			scene_item_selected.emit(
					event_data.get("sceneName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("sceneUuid", "")),
					event_data.get("sceneItemId", 0),
			)
		"SceneItemTransformChanged":
			scene_item_transform_changed.emit(
					event_data.get("sceneName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("sceneUuid", "")),
					event_data.get("sceneItemId", 0),
					event_data.get("sceneItemTransform", {}),
			)
		"SceneListChanged":
			scene_list_changed.emit(event_data.get("scenes", []))
		"SceneNameChanged":
			scene_name_changed.emit(
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("sceneUuid", "")),
					event_data.get("oldSceneName", ""),
					event_data.get("sceneName", ""),
			)
		"SceneRemoved":
			scene_removed.emit(
					event_data.get("sceneName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("sceneUuid", "")),
					event_data.get("is_group", false)
			)
		"SceneTransitionEnded":
			scene_transition_ended.emit(
					event_data.get("transitionName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("transitionUuid", "")),
			)
		"SceneTransitionStarted":
			scene_transition_started.emit(
					event_data.get("transitionName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("transitionUuid", "")),
			)
		"SceneTransitionVideoEnded":
			scene_transition_video_ended.emit(
					event_data.get("transitionName", ""),
					VulpineLogicOBSWebSocketRequest.string_to_uuid(event_data.get("transitionUuid", "")),
			)
		"ScreenshotSaved":
			screenshot_saved.emit(event_data.get("savedScreenshotPath", ""))
		"SourceFilterCreated":
			source_filter_created.emit(
					VulpineLogicOBSWebSocketRequest.snake_case_dictionary(event_data)
			)
		"SourceFilterEnableStateChanged":
			source_filter_enable_state_changed.emit(
					event_data.get("sourceName", ""),
					event_data.get("filterName", ""),
					event_data.get("filterEnabled", false),
			)
		"SourceFilterListReindexed":
			source_filter_list_reindexed.emit(
					event_data.get("sourceName", ""),
					event_data.get("filters", []),
			)
		"SourceFilterNameChanged":
			source_filter_name_changed.emit(
					event_data.get("sourceName", ""),
					event_data.get("oldFilterName", ""),
					event_data.get("filterName", ""),
			)
		"SourceFilterRemoved":
			source_filter_removed.emit(
					event_data.get("sourceName", ""),
					event_data.get("filterName", ""),
			)
		"SourceFilterSettingsChanged":
			source_filter_settings_changed.emit(
					event_data.get("sourceName", ""),
					event_data.get("filterName", ""),
					event_data.get("filterSettings", {}),
			)
		"StreamStateChanged":
			stream_state_changed.emit(
					event_data.get("output_active", false),
					event_data.get("output_state", ""),
			)
		"StudioModeStateChanged":
			studio_mode_state_changed.emit(
					event_data.get("studio_mode_enabled", false)
			)
		"VendorEvent":
			vendor_event_received.emit(
					event_data.get("vendorName", ""),
					event_data.get("eventType", ""),
					event_data.get("eventData", {})
			)
		"VirtualcamStateChanged":
			virtualcam_state_changed.emit(
					event_data.get("outputActive", false),
					event_data.get("outputState", "")
			)
		_:
			print_debug(event)


func _handle_hello(payload: Dictionary) -> void:
	print("OBS WebSocket %s (rpc %d)" % [
			payload.get("obsWebSocketVersion", "UNKNOWN"),
			payload.get("rpcVersion", 0) as int
	])
	
	if not "authentication" in payload:
		_identify()
		return

	var auth = payload.authentication
	var challenge = auth.challenge as String
	var salt = auth.salt as String
	
	var salted_password = password + salt
	var hc = HashingContext.new()
	
	if hc.start(HashingContext.HASH_SHA256) != OK:
		_close()
		return
		
	if hc.update(salted_password.to_ascii_buffer()) != OK:
		_close()
		return
		
	var secret = Marshalls.raw_to_base64(hc.finish())
	var response = secret + challenge
	
	hc = HashingContext.new()

	if hc.start(HashingContext.HASH_SHA256) != OK:
		_close()
		return
		
	if hc.update(response.to_ascii_buffer()) != OK:
		_close()
		return

	var authentication = Marshalls.raw_to_base64(hc.finish())
	_identify(EventSubscription.ALL, authentication)


func _handle_identified(event: Dictionary) -> void:
	_negotiated_rpc_version = event.get("negotiatedRpcVersion", 0)
	identified.emit(VulpineLogicOBSWebSocketRequest.snake_case_dictionary(event))


func _handle_request_response(response: Dictionary) -> void:
	var request_id = response.requestId
	
	if request_id not in _pending_requests:
		return
	
	_pending_requests[request_id].response = response


func _identify(
		event_subscriptions: int = EventSubscription.ALL,
		authentication: String = ""
) -> void:
	var message = {
		"op": 1,
		"d": {
			"rpcVersion": 1,
			"eventSubscriptions": event_subscriptions
		}
	}
	
	if not authentication.is_empty():
		message.d.authentication = authentication
		
	_websocket.send_text(JSON.stringify(message))


func _open() -> void:
	if password.is_empty():
		_queue_reconnect()
		return
	
	_websocket.poll()
	
	if _websocket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		var error = _websocket.connect_to_url(host)
		
		if error != OK:
			connection_failed.emit(error)
			_queue_reconnect()
		
		_process_state = _process_state_connecting


func _process_state_closed(ready_state: int) -> void:
	match ready_state:
		WebSocketPeer.State.STATE_CLOSING:
			_process_state = _process_state_closing
		WebSocketPeer.State.STATE_CONNECTING:
			_process_state = _process_state_connecting
		WebSocketPeer.State.STATE_OPEN:
			connected.emit()
			_process_state = _process_state_open


func _process_state_closing(ready_state: int) -> void:
	match ready_state:
		WebSocketPeer.State.STATE_CLOSED:
			var close_code = _websocket.get_close_code()
			_negotiated_rpc_version = 0
			closed.emit(close_code)
			_queue_reconnect()
			_process_state = _process_state_closed
		WebSocketPeer.State.STATE_CONNECTING:
			_process_state = _process_state_connecting
		WebSocketPeer.State.STATE_OPEN:
			connected.emit()
			_process_state = _process_state_open


func _process_state_connecting(ready_state: int) -> void:
	match ready_state:
		WebSocketPeer.State.STATE_CLOSED:
			connection_failed.emit(0)
			_queue_reconnect()
			_process_state = _process_state_closed
		WebSocketPeer.State.STATE_CLOSING:
			_process_state = _process_state_closing
		WebSocketPeer.State.STATE_OPEN:
			connected.emit()
			_process_state = _process_state_open


func _process_state_open(ready_state: int) -> void:
	match ready_state:
		WebSocketPeer.State.STATE_CLOSED:
			var close_code = _websocket.get_close_code()
			_negotiated_rpc_version = 0
			closed.emit(close_code)
			_queue_reconnect()
			_process_state = _process_state_closed
		WebSocketPeer.State.STATE_CLOSING:
			_process_state = _process_state_closing
		WebSocketPeer.State.STATE_CONNECTING:
			_process_state = _process_state_connecting


func _queue_reconnect(delay: float = reconnect_delay) -> void:
	get_tree().create_timer(delay).timeout.connect(_open)


class EventSubscription:
	const NONE = 0
	const GENERAL = 1 << 0
	const CONFIG = 1 << 1
	const SCENES = 1 << 2
	const INPUTS = 1 << 3
	const TRANSITIONS = 1 << 4
	const FILTERS = 1 << 5
	const OUTPUTS = 1 << 6
	const SCENE_ITEMS = 1 << 7
	const MEDIA_INPUTS = 1 << 8
	const VENDORS = 1 << 9
	const UI = 1 << 10
	const ALL = ( 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6
			| 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10
	)
	const INPUT_VOLUME_METERS = 1 << 16
	const INPUT_ACTIVE_STATE_CHANGED = 1 << 17
	const INPUT_SHOW_STATE_CHANGED = 1 << 18
	const SCENE_ITEM_TRANSFORM_CHANGED = 1 << 19


class RequestStatus:
	const UNKNOWN = 0
	const NO_ERROR = 10
	const SUCCESS = 100
	const MISSING_REQUEST_TYPE = 203
	const UNKNOWN_REQUEST_TYPE = 204
	const GENERIC_ERROR = 205
	const UNSUPPORTED_REQUEST_BATCH_EXECUTION_TYPE = 206
	const NOT_READY = 207
	const MISSING_REQUEST_FIELD = 300
	const MISSING_REQUEST_DATA = 301
	const INVALID_REQUEST_FIELD = 400
	const INVALID_REQUEST_FIELD_TYPE = 401
	const REQUEST_FIELD_OUT_OF_RANGE = 402
	const REQUEST_FIELD_EMPTY = 403
	const TOO_MANY_REQUEST_FIELDS = 404
	const OUTPUT_RUNNING = 500
	const OUTPUT_NOT_RUNNING = 501
	const OUTPUT_PAUSED = 502
	const OUTPUT_NOT_PAUSED = 503
	const OUTPUT_DISABLED = 504
	const STUDIO_MODE_ACTIVE = 505
	const STUDIO_MODE_NOT_ACTIVE = 506
	const RESOURCE_NOT_FOUND = 600
	const RESOURCE_ALREADY_EXISTS = 601
	const INVALID_RESOURCE_TYPE = 602
	const NOT_ENOUGH_RESOURCES = 603
	const INVALID_RESOURCE_STATE = 604
	const INVALID_INPUT_KIND = 605
	const RESOURCE_NOT_CONFIGURABLE = 606
	const INVALID_FILTER_KIND = 607
	const RESOURCE_CREATION_FAILED = 700
	const RESOURCE_ACTION_FAILED = 701
	const REQUEST_PROCESSING_FAILED = 702
	const CANNOT_ACT = 703


class WebSocketCloseCode:
	const DONT_CLOSE = 0
	const NORMAL_CLOSURE = 1000
	const GOING_AWAY = 1001
	const UNKNOWN_REASON = 4000
	const MESSAGE_DECODE_ERROR = 4002
	const MISSING_DATA_FIELD = 4003
	const INVALID_DATA_FIELD_TYPE = 4004
	const INVALID_DATA_FIELD_VALUE = 4005
	const UNKNOWN_OP_CODE = 4006
	const NOT_IDENTIFIED = 4007
	const ALREADY_IDENTIFIED = 4008
	const AUTHENTICATION_FAILED = 4009
	const UNSUPPORTED_RPC_VERSION = 4010
	const SESSION_INVALIDATED = 4011
	const UNSUPPORTED_FEATURE = 4012
	
	static var code_strings = {
		DONT_CLOSE: "DontClose",
		NORMAL_CLOSURE: "NormalClosure",
		GOING_AWAY: "GoingAway",
		UNKNOWN_REASON: "UnknownReason",
		MESSAGE_DECODE_ERROR: "MessageDecodeError",
		MISSING_DATA_FIELD: "MissingDataField",
		INVALID_DATA_FIELD_TYPE: "InvalidDataFieldType",
		INVALID_DATA_FIELD_VALUE: "InvalidDataFieldValue",
		UNKNOWN_OP_CODE: "UnknownOpCode",
		NOT_IDENTIFIED: "NotIdentified",
		ALREADY_IDENTIFIED: "AlreadyIdentified",
		AUTHENTICATION_FAILED: "AuthenticationFailed",
		UNSUPPORTED_RPC_VERSION: "UnsupportedRpcVersion",
		SESSION_INVALIDATED: "SessionInvalidated",
		UNSUPPORTED_FEATURE: "UnsupportedFeature",
	}
	
	
	static func code_string(code: int) -> String:
		var string = code_strings.get(code, "")
		return string if not string.is_empty() else "%d" % code
