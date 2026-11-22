extends Area3D

const GPUPlatform = preload("res://gpu_platform.gd")

const SPIN_SPEED = 2.5
const BOB_HEIGHT = 0.25

var start_y = 0.0
var time = 0.0


func _ready() -> void:
	start_y = position.y
	time = randf() * TAU
	GPUPlatform.paint($Sketchfab_Scene, 0.6)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	time += delta
	rotation.y += SPIN_SPEED * delta
	position.y = start_y + sin(time * 3.0) * BOB_HEIGHT


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.add_gpu()
		queue_free()
