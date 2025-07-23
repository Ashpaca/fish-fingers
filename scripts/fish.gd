extends CharacterBody3D

@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var fishModel : MeshInstance3D = $FishMesh

var swimming : bool = true
var rotationGoal : float = 0.0
var swimHeight : float = 0.0

func _ready() -> void:
	navAgent.target_position = global_position

func _physics_process(delta: float) -> void:
	if not swimming:
		navAgent.target_position = global_position + Vector3.RIGHT * randf_range(-5, 5) + Vector3.FORWARD * randf_range(-5, 5)
		while !navAgent.is_target_reachable():
			navAgent.target_position = global_position + Vector3.RIGHT * randf_range(-5, 5) + Vector3.FORWARD * randf_range(-5, 5)
		swimHeight = randf_range(0, 1.5)
		swimming = true
	elif (navAgent.target_position - global_position).length_squared() > 1.1:
		var direction : Vector3 = (navAgent.get_next_path_position() - global_position).normalized()
		rotationGoal = atan2(direction.x, direction.z)
		velocity = direction * 1.2
		fishModel.position = fishModel.position.lerp(Vector3.UP * swimHeight, 0.02)
	else:
		swimming = false
	
	rotate_fish_model(delta)
	move_and_slide()


func rotate_fish_model(delta : float) -> void:
	var max_angle = PI * 2
	var difference = fmod(rotationGoal - rotation.y, max_angle)
	rotation.y = rotation.y + (fmod(2 * difference, max_angle) - difference) * delta * 3


func _on_bubble_sprite_frame_changed() -> void:
	pass # Replace with function body.
