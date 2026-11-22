extends Area3D

enum Kind { BOUNCE, CHECKPOINT, FINISH }

@export var kind: Kind = Kind.BOUNCE
@export var bounce_force = 24.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	match kind:
		Kind.BOUNCE:
			body.bounce(bounce_force)
			var tween = create_tween()
			scale = Vector3(1.2, 0.6, 1.2)
			tween.tween_property(self, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC)
		Kind.CHECKPOINT:
			body.set_checkpoint(global_position + Vector3.UP)
		Kind.FINISH:
			body.finish()
