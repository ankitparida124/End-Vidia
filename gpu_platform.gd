extends AnimatableBody3D

# A giant GPU from gpu.glb used as a platform. It can slide back and forth
# and spin like a fan, Stumble Guys style.
@export var platform_scale = 1.0
@export var move_offset = Vector3.ZERO
@export var move_period = 4.0
@export var spin_speed = 0.0

# The model ships with one grey material, so each part gets an NVIDIA colour.
const PART_COLORS = {
	"GPU_OuterCase": Color(0.46, 0.73, 0.0),
	"GPU_FAN": Color(0.09, 0.1, 0.12),
	"GPU_Backplate": Color(0.09, 0.1, 0.12),
	"GPU_Heatsink": Color(0.55, 0.57, 0.6),
	"GPU_Metal": Color(0.55, 0.57, 0.6),
	"GPU_IO": Color(0.55, 0.57, 0.6),
	"GPU_PCB": Color(0.05, 0.35, 0.15),
	"GPU_PWR": Color(0.09, 0.1, 0.12),
}

var start_position = Vector3.ZERO
var time = 0.0


static func paint(model: Node, emission: float = 0.0) -> void:
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for part in PART_COLORS:
			if mesh.name.begins_with(part):
				var material = StandardMaterial3D.new()
				material.albedo_color = PART_COLORS[part]
				material.metallic = 0.6 if part in ["GPU_Heatsink", "GPU_Metal", "GPU_IO"] else 0.1
				material.roughness = 0.35
				if emission > 0.0:
					material.emission_enabled = true
					material.emission = PART_COLORS[part]
					material.emission_energy_multiplier = emission
				mesh.material_override = material


func _ready() -> void:
	start_position = position
	$Model.transform = $Model.transform.scaled(Vector3.ONE * platform_scale)
	paint($Model)
	var collision: CollisionShape3D = $CollisionShape3D
	collision.position *= platform_scale
	collision.shape = collision.shape.duplicate()
	collision.shape.size *= platform_scale


func _physics_process(delta: float) -> void:
	time += delta
	if move_offset:
		position = start_position + move_offset * sin(time * TAU / move_period)
	if spin_speed:
		rotation.y += deg_to_rad(spin_speed) * delta
