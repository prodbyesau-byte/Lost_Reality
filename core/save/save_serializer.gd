class_name SaveSerializer
extends RefCounted
## Hash the exact embedded payload bytes, avoiding JSON number/key canonicalization.
static func encode(payload: Dictionary) -> String:
	var body := JSON.stringify(payload)
	return JSON.stringify({"format": SaveConstants.FORMAT, "sha256": body.sha256_text(), "payload": body})

static func decode(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return {"ok": false, "error": "Malformed save envelope."}
	var envelope: Dictionary = json.data
	if envelope.get("format") != SaveConstants.FORMAT or not envelope.get("payload") is String or not envelope.get("sha256") is String:
		return {"ok": false, "error": "Unrecognized save format."}
	var body: String = envelope.payload
	if body.sha256_text() != envelope.sha256:
		return {"ok": false, "error": "Save checksum mismatch."}
	if json.parse(body) != OK or not json.data is Dictionary:
		return {"ok": false, "error": "Malformed save payload."}
	return {"ok": true, "data": json.data, "revision": envelope.sha256}

static func vector(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

static func to_vector(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])
