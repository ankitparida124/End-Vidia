extends Node3D

# Spinning sweeper bar that knocks the runner around.
@export var spin_speed = 90.0
@export var push_strength = 18.0

@onready var arm: Node3D = $Arm


func _ready() -> void:
	$Arm/HitArea.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	arm.rotation.y += deg_to_rad(spin_speed) * delta


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("hit"):
		var from_center = body.global_position - global_position
		from_center.y = 0
		var sweep = Vector3.UP.cross(from_center).normalized() * sign(spin_speed)
		if body.is_in_group("player"):
			body.hit(sweep + from_center.normalized() * 0.5, push_strength)
		else:
			body.hit(sweep)
