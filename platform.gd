extends Node3D
@export var cameras : Array[Camera3D]=[]
var current_index = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_camera()# Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func update_camera():
	for i in range(cameras.size()):
		cameras[i]= (i == current_index)
func _on_button_pressed() -> void:
	current_index=(current_index+1)% cameras.size()
	update_camera()		
		
