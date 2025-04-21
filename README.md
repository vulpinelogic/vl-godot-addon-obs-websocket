# vulpinelogic_obs_websocket

Connect to OBS via WebSocket, make requests, and receive events.

This repository only contains the add-on. A demo will be provided at some time
in the future.

## Features

- Partial implementation of the OBS WebSocket spec
- Minimal connection management (auto-connect/-reconnect)

## Installation

### Using the Asset Library

This addon will be submitted to the Asset Library once it reaches a 1.0.0 release. There is no estimated release date.

### Manual installation

Manual installation lets you use pre-release versions of this add-on by
following its `main` branch.

- Clone this Git repository:

```bash
git clone https://github.com/vulpinelogic/vl-godot-addon-obs-websocket.git
```

Alternatively, you can
[download a ZIP
archive](https://github.com/vulpinelogic/vl-godot-addon-obs-websocket/archive/master.zip)
if you do not have Git installed.

- Move the `addons/` folder to your project folder.
- In the editor, open **Project > Project Settings**, go to **Plugins**
  and enable the **vulpinelogic_obs_websocket** plugin.

## Usage

**This addon has only been tested with Godot 4.x**

Add a `VulpineLogicOBSWebSocket` node to your scene tree, or register an
autoload global that points to the
`addons/vulpinelogic_obs_websocket/websocket/obs_websocket.gd` script.

```gdscript
var ws: VulpineLogicOBSWebSocket = $OBSWebSocket

ws.identified.connect(
		func (_event):
			var scenes = await ws.get_scene_list()
			print(scenes)
)

ws.password = "password"
```

This addon is an incomplete implementation of the OBS WebSocket feature set.
Most events are supported, but many requests have not been implemented. Open an
issue or submit a PR to have additional requests added.

### Requests

Implemented requests are located in
`addons/vulpinelogic_obs_websocket/websocket/requests` and are expected to
inherit from the `VulpineLogicOBSWebsocketRequest` class. If a request expects
parameters, these should be set via an optional `_init` method. In order to make
alterations to the response before it is returned to the caller, implement
`_transform_response(raw_response: Dictionary) -> Variant`.

Example:

```gdscript
func _transform_response(raw_response: Dictionary) -> Dictionary:
	# If super is not called, keys will not have been converted from camel
	# case to snake case. Do not skip calling super unless you intend to
	# make the snake case conversion yourself.
	var xformed_response = super(raw_response)
	
	# Make your alterations here

	return xformed_response
```

`VulpineLogicOBSWebSocketRequest` provides several static methods that
contributors may find useful.

- `camel_case_dictionary` converts a dictionary's keys to camel case
- `snake_case_dictionary` convers a dictionary's keys to snake case
- `is_uuid` will return true if a String is prefixed with `uuid://`
- `string_to_uuid` will return a `uuid://` prefixed String if the prefix is not
  already present
- `uuid_to_string` will strip the `uuid://` prefix from a String

Instances of `VulpineLogicOBSWebSocketRequest` have access to the
`set_resource_request_field` method that can be used to add an appropriately
suffixed field to the request (typically done in `_init`) based on whether the
value provided is `uuid://` prefixed. For example,
`set_resource_request_field("scene", "uuid://scene-uuid-value")` will add the
key `sceneUuid` and the value `uuid://scene-uuid-value` to the request.

## License

Copyright © 2025 VulpineLogic and contributors

Unless otherwise specified, files in this repository are licensed under the
MIT license. See [LICENSE.md](LICENSE.md) for more information.

