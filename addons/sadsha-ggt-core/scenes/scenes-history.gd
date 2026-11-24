extends RefCounted

const config = preload("res://addons/sadsha-ggt-core/config.tres")
var _history: Array[SadShaGGT_SceneData] = []


func add(scene_path: String, params = null):
	var data = SadShaGGT_SceneData.new()
	data.path = scene_path
	data.params = params
	_history.push_front(data)
	while _history.size() > config.max_history_length:
		_history.pop_back()


func get_last_loaded_scene_data() -> SadShaGGT_SceneData:
	if _history.size() == 0:
		return null
	return _history[0]
