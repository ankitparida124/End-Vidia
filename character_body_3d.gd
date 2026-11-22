extends CharacterBody3D

signal gpus_changed(total)
signal fell
signal enemy_knocked_out
signal finished

const SPEED = 12
const JUMP_VELOCITY = 15
const GRAVITY_SCALE = 3.0
const PUNCH_RANGE = 2.2
const PUNCH_COOLDOWN = 0.45
const STOMP_BOUNCE = 11
const FALL_LIMIT = -25.0
const MOUSE_SENSITIVITY = 0.004

# Animations come from the female character pack and are retargeted onto
# the male runner at import time (both skeletons share the humanoid profile).
const ANIMATION_SOURCE = preload("res://assets/characters/female/Casual.gltf")

@onready var model: Node3D = $Model
@onready var anim: AnimationPlayer = $Model/AnimationPlayer
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

var gpus = 0
var spawn_point = Vector3.ZERO
var knockback = Vector3.ZERO
var stun_time = 0.0
var punch_time = 0.0
var has_finished = false


func _ready() -> void:
	add_to_group("player")
	spawn_point = global_position
	var source = ANIMATION_SOURCE.instantiate()
	var library: AnimationLibrary = source.get_node("AnimationPlayer").get_animation_library("")
	for loop_name in ["Idle", "Run", "Walk"]:
		library.get_animation(loop_name).loop_mode = Animation.LOOP_LINEAR
	anim.remove_animation_library("")
	anim.add_animation_library("", library)
	source.free()
	anim.play("Idle")
	model.rotation.y = PI
	camera_pivot.top_level = true
	camera_pivot.global_position = global_position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotation.y -= event.relative.x * MOUSE_SENSITIVITY


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * GRAVITY_SCALE * delta

	stun_time = max(stun_time - delta, 0.0)
	punch_time = max(punch_time - delta, 0.0)
	knockback = knockback.move_toward(Vector3.ZERO, 30 * delta)

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and stun_time == 0.0:
		velocity.y = JUMP_VELOCITY

	# Handle punch.
	if Input.is_action_just_pressed("punch") and punch_time == 0.0 and stun_time == 0.0:
		punch()

	# Get the input direction relative to the camera and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if has_finished or stun_time > 0.0:
		input_dir = Vector2.ZERO
	var direction := (camera_pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	direction.y = 0
	direction = direction.normalized()
	if direction:
		velocity.x = direction.x * SPEED + knockback.x
		velocity.z = direction.z * SPEED + knockback.z
		model.rotation.y = lerp_angle(model.rotation.y, atan2(direction.x, direction.z), 12 * delta)
	else:
		velocity.x = move_toward(velocity.x, knockback.x, SPEED)
		velocity.z = move_toward(velocity.z, knockback.z, SPEED)

	move_and_slide()
	check_stomp()

	if global_position.y < FALL_LIMIT:
		respawn()

	update_animation(direction)


func _process(delta: float) -> void:
	# Smooth follow camera, Stumble Guys style.
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position + Vector3(0, 1.5, 0), 10 * delta)


func update_animation(direction: Vector3) -> void:
	if has_finished:
		play_animation("Wave")
	elif stun_time > 0.0:
		play_animation("HitRecieve")
	elif punch_time > 0.0:
		return
	elif not is_on_floor():
		play_animation("Run", 0.6)
	elif direction:
		play_animation("Run", 1.3)
	else:
		play_animation("Idle")


func play_animation(anim_name: String, speed: float = 1.0) -> void:
	if anim.current_animation != anim_name:
		anim.play(anim_name, 0.15)
	anim.speed_scale = speed


func punch() -> void:
	punch_time = PUNCH_COOLDOWN
	anim.play("Punch_Right" if randf() < 0.5 else "Punch_Left", 0.05)
	anim.speed_scale = 1.8
	var facing = Vector3(sin(model.rotation.y), 0, cos(model.rotation.y))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var to_enemy: Vector3 = enemy.global_position - global_position
		if to_enemy.length() < PUNCH_RANGE and facing.dot(to_enemy.normalized()) > 0.3:
			enemy.hit(facing, true)


func check_stomp() -> void:
	# Jumping on an enemy's head knocks her out and bounces the runner up.
	for i in get_slide_collision_count():
		var body = get_slide_collision(i).get_collider()
		if body and body.is_in_group("enemies") and global_position.y > body.global_position.y + 1.2:
			body.hit(Vector3(velocity.x, 0, velocity.z).normalized(), true)
			velocity.y = STOMP_BOUNCE


func hit(push_direction: Vector3, strength: float = 10.0) -> void:
	if has_finished or stun_time > 0.0:
		return
	knockback = push_direction.normalized() * strength
	velocity.y = 6
	stun_time = 0.5


func bounce(force: float) -> void:
	velocity.y = force


func add_gpu() -> void:
	gpus += 1
	gpus_changed.emit(gpus)


func knocked_out_enemy() -> void:
	enemy_knocked_out.emit()


func set_checkpoint(point: Vector3) -> void:
	spawn_point = point


func finish() -> void:
	if not has_finished:
		has_finished = true
		finished.emit()


func respawn() -> void:
	global_position = spawn_point
	velocity = Vector3.ZERO
	knockback = Vector3.ZERO
	camera_pivot.global_position = global_position
	fell.emit()
