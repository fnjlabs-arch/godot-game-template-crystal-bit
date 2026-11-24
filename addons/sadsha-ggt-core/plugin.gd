@tool
extends EditorPlugin


func _enter_tree():
	pass


func _enable_plugin():
	add_autoload_singleton("SadShaGGT", "res://addons/sadsha-ggt-core/sadsha_ggt.gd")
	add_autoload_singleton("SadShaGGT_GameConfig", "res://addons/sadsha-ggt-core/autoload/game_settings_config.gd")


func _exit_tree():
	pass


func _disable_plugin():
	remove_autoload_singleton("SadShaGGT")
	remove_autoload_singleton("SadShaGGT_GameConfig")
