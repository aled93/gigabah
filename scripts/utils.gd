class_name Utils
extends Node

static func get_human_readable_byte_size(byte_size: int) -> String:
	if byte_size < 1024:
		return "%d B" % byte_size

	if byte_size < 1024 ** 2:
		return "%.2f KB" % (byte_size / 1024.0)

	if byte_size < 1024 ** 3:
		return "%.2f MB" % (byte_size / 1024.0 ** 2)

	if byte_size < 1024 ** 4:
		return "%.2f GB" % (byte_size / 1024.0 ** 3)

	if byte_size < 1024 ** 5:
		return "%.2f TB" % (byte_size / 1024.0 ** 4)

	if byte_size < 1024 ** 6:
		return "%.2f PB" % (byte_size / 1024.0 ** 5)

	if byte_size < 1024 ** 7:
		return "%.2f EB" % (byte_size / 1024.0 ** 6)

	if byte_size < 1024 ** 8:
		return "%.2f ZB" % (byte_size / 1024.0 ** 7)

	if byte_size < 1024 ** 9:
		return "%.2f YB" % (byte_size / 1024.0 ** 8)

	return "TOO MUCH"


static func get_human_readable_duration_short(secs: float) -> String:
	var v: float
	var s: String
	var neg := secs < 0.0

	if neg:
		secs = -secs

	if secs < 1.0:
		v = secs
		s = TranslationServer.translate(&"duration_short_milliseconds") % v
	elif secs < 60.0:
		v = secs
		s = TranslationServer.translate(&"duration_short_seconds") % v
	elif secs < 60.0 * 60.0:
		v = secs / 60.0
		s = TranslationServer.translate(&"duration_short_minutes") % v
	elif secs < 60.0 * 60.0 * 24.0:
		v = secs / 60.0 / 60.0
		s = TranslationServer.translate(&"duration_short_hours") % v
	elif secs < 60.0 * 60.0 * 24.0 * 7.0:
		v = secs / 60.0 / 60.0 / 24.0
		s = TranslationServer.translate(&"duration_short_days") % v
	elif secs < 60.0 * 60.0 * 24.0 * 7.0 * 30.0:
		v = secs / 60.0 / 60.0 / 24.0 / 7.0
		s = TranslationServer.translate(&"duration_short_weeks") % v
	elif secs < 60.0 * 60.0 * 24.0 * 7.0 * 30.0 * 12.0:
		v = secs / 60.0 / 60.0 / 24.0 / 7.0 / 30.0
		s = TranslationServer.translate(&"duration_short_months") % v
	else:
		v = secs / 60.0 / 60.0 / 24.0 / 7.0 / 30.0 / 12.0
		s = TranslationServer.translate(&"duration_short_years") % v

	return TranslationServer.translate(&"time_diff_ago") % s if neg else s


# array is variant to receive both untyped `Array` and typed packed
# arrays like `PackedInt32Array`
static func array_erase_replacing(array: Variant, index: int) -> void:
	if index < 0 or index >= array.size():
		return

	if array.size() == 1:
		array.clear()
		return

	var last_idx: int = array.size() - 1
	if index < last_idx:
		array[index] = array[last_idx]
	array.resize(last_idx)
