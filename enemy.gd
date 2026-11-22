extends CharacterBody3D

const SPEED = 5.5
const CHASE_RANGE = 12.0
const ATTACK_RANGE = 1.6
const ATTACK_COOLDOWN = 1.4
const PATROL_RADIUS = 3.0

@export var character: PackedScene

var model: Node3D
var anim: AnimationPlayer
var home = Vector3.ZERO
var patrol_target = Vector3.ZERO
var attack_time = 0.0
var knocked_out = false
var player: Node3D


func _ready() -> void:
	add_to_group("enemies")
	home = global_position
	patrol_target = home
	model = character.instantiate()
	add_child(model)
	anim = model.get_node("AnimationPlayer")
	for loop_name in ["Idle", "Run", "Walk"]:
		anim.get_animation(loop_name).loop_mode = Animation.LOOP_LINEAR
	anim.play("Idle")
	attack_time = randf() * ATTACK_COOLDOWN


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * 3.0 * delta

	if knocked_out:
		velocity.x = move_toward(velocity.x, 0, 10 * delta)
		velocity.z = move_toward(velocity.z, 0, 10 * delta)
		move_and_slide()
		return

	if player == null:
		player = get_tree().get_first_node_in_group("player")
	attack_time = max(attack_time - delta, 0.0)

	var direction = Vector3.ZERO
	var to_player: Vector3 = player.global_position - global_position
	var flat_distance = Vector2(to_player.x, to_player.z).length()
	if flat_distance < CHASE_RANGE and abs(to_player.y) < 2.5 and (player.global_position - home).length() < CHASE_RANGE:
		face(to_player)
		if flat_distance < ATTACK_RANGE:
			if attack_time == 0.0:
				attack()
		else:
			direction = Vector3(to_player.x, 0, to_player.z).normalized()
	else:
		# Wander around the spawn point.
		var to_target = patrol_target - global_position
		to_target.y = 0
		if to_target.length() < 0.5:
			patrol_target = home + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * PATROL_RADIUS
		else:
			direction = to_target.normalized() * 0.4
			face(to_target)

	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()

	if anim.current_animation.begins_with("Punch") and anim.is_playing():
		return
	if direction.length() > 0.5:
		play_animation("Run")
	elif direction:
		play_animation("Walk")
	else:
		play_animation("Idle")


func face(target_direction: Vector3) -> void:
	model.rotation.y = atan2(target_direction.x, target_direction.z)


func play_animation(anim_name: String) -> void:
	if anim.current_animation != anim_name:
		anim.play(anim_name, 0.2)


func attack() -> void:
	attack_time = ATTACK_COOLDOWN
	anim.play("Punch_Right", 0.1)
	await get_tree().create_timer(0.25).timeout
	if knocked_out:
		return
	var to_player: Vector3 = player.global_position - global_position
	if to_player.length() < ATTACK_RANGE + 0.6:
		player.hit(Vector3(to_player.x, 0, to_player.z))


func hit(push_direction: Vector3, by_player: bool = false) -> void:
	if knocked_out:
		return
	knocked_out = true
	collision_layer = 0
	velocity = push_direction.normalized() * 9 + Vector3.UP * 7
	anim.play("Death", 0.1)
	if by_player:
		player.knocked_out_enemy()
	await get_tree().create_timer(2.0).timeout
	queue_free()
