class_name Utils
extends Node

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
