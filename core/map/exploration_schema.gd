class_name ExplorationSchema
extends RefCounted
## 16x16 cells / 256 bits / 64 hex characters per discovered chunk.
const CHUNK := 16
const BYTES := 32
const HEX_LENGTH := 64

static func defaults() -> Dictionary:
	return {"zones": {}}

static func chunk_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x / CHUNK, cell.y / CHUNK]

static func bit_index(cell: Vector2i) -> int:
	return (cell.y % CHUNK) * CHUNK + cell.x % CHUNK

static func has_cell(chunks: Dictionary, cell: Vector2i) -> bool:
	var mask: String = chunks.get(chunk_key(cell), "")
	if mask.is_empty():
		return false
	var bit := bit_index(cell)
	var byte_value := mask.substr((bit / 8) * 2, 2).hex_to_int()
	return (byte_value & (1 << (bit % 8))) != 0

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 1 or not value.get("zones") is Dictionary:
		return false
	for zone_id in value.zones:
		if not zone_id is String:
			return false
		var area := MapCatalog.zone(zone_id)
		var zone: Variant = value.zones[zone_id]
		if area == null or not zone is Dictionary or zone.size() != 2 or not zone.get("chunks") is Dictionary or not zone.get("pois") is Dictionary:
			return false
		for key in zone.chunks:
			if not key is String:
				return false
			var parts: PackedStringArray = key.split(",")
			if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
				return false
			var chunk := Vector2i(int(parts[0]), int(parts[1]))
			if key != "%d,%d" % [chunk.x, chunk.y] or not area.contains(chunk * CHUNK):
				return false
			var mask: Variant = zone.chunks[key]
			if not mask is String or mask.length() != HEX_LENGTH:
				return false
			for character in mask:
				if not character in "0123456789abcdef":
					return false
			var bytes: PackedByteArray = mask.hex_decode()
			var any_bit := false
			for bit in CHUNK * CHUNK:
				if (bytes[bit / 8] & (1 << (bit % 8))) != 0:
					any_bit = true
					if not area.contains(chunk * CHUNK + Vector2i(bit % CHUNK, bit / CHUNK)):
						return false
			if not any_bit:
				return false
		for id in zone.pois:
			if not area.definition.pois.has(id) or not zone.pois[id] is bool or not zone.pois[id]:
				return false
			var pos: Array = area.definition.pois[id].position
			if not has_cell(zone.chunks, area.cell_at(Vector2(pos[0], pos[2]))):
				return false
	return true
