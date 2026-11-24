extends Node

signal scene_transition_started
signal scene_transition_finished

const _SadShaGGT_Transitions = preload("res://addons/sadsha-ggt-core/transitions/transitions.tscn")
const _config = preload("res://addons/sadsha-ggt-core/config.tres")

@onready var _history = preload("res://addons/sadsha-ggt-core/scenes/scenes-history.gd").new()
@onready var _loader_mt = preload("res://addons/sadsha-ggt-core/utils/resource_multithread_loader.gd").new()

var _transitions: Node
var _loading_start_time = 0
var _changing_scene = false


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cur_scene: Node = get_tree().current_scene
	_history.add(cur_scene.scene_file_path, {})

	_transitions = _SadShaGGT_Transitions.instantiate()
	get_node("/root").call_deferred("add_child", _transitions)
	_loader_mt.connect("resource_stage_loaded", _transitions._on_resource_stage_loaded)


func get_current_scene_data() -> SadShaGGT_SceneData:
	if _history:
		return _history.get_last_loaded_scene_data()
	else:
		return SadShaGGT_SceneData.new()


func change_scene(new_scene: String, params = {}):
	if not ResourceLoader.exists(new_scene):
		push_error("Scene resource not found: ", new_scene)
		return
	_changing_scene = true
	emit_signal("scene_transition_started", new_scene, params)
	_history.add(new_scene, params)
	_loading_start_time = Time.get_ticks_msec()
	_transition_appear(params)
	_loader_mt.connect("resource_loaded", _on_resource_loaded, CONNECT_ONE_SHOT)
	await _transitions.transition_covered_screen
	_loader_mt.load_resource(new_scene)


# Restart the current scene
func restart_scene():
	var scene_data = get_current_scene_data()
	change_scene(scene_data.path, scene_data.params)


# Restart the current scene, but use given params
func restart_scene_with_params(override_params):
	var scene_data = get_current_scene_data()
	change_scene(scene_data.path, override_params)


func is_changing_scene() -> bool:
	return _changing_scene


func _set_new_scene(resource: PackedScene):
	get_tree().change_scene_to_packed(resource)
	_transitions.fade_out()
	await _transitions.anim.animation_finished
	emit_signal("scene_transition_finished")
	_loading_start_time = 0
	_changing_scene = false


func _transition_appear(params):
	_transitions.fade_in(params)


func _on_resource_loaded(resource):
	if _transitions.is_transition_in_playing():
		await _transitions.anim.animation_finished
	var load_time = Time.get_ticks_msec() - _loading_start_time # ms
	print(
		"[SadShaGGT] {scn} loaded in {elapsed}ms".format({"scn": resource.resource_path, "elapsed": load_time})
	)
	# artificially wait some time in order to have a gentle scene transition
	if load_time < _config.transitions_minimum_duration_ms:
		await get_tree().create_timer((_config.transitions_minimum_duration_ms - load_time) / 1000.0).timeout
	_set_new_scene(resource)
