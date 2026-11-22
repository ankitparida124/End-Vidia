extends Node3D

@onready var player = $Player
@onready var hud = $HUD


func _ready() -> void:
	player.gpus_changed.connect(hud.on_gpus_changed)
	player.enemy_knocked_out.connect(hud.on_enemy_knocked_out)
	player.fell.connect(hud.on_fell)
	player.finished.connect(hud.on_finished)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
