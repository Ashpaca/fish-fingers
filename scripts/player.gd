class_name Player extends CharacterBody3D


const SPEED = 2.5
const ROTATE_SPEED = 0.03

@onready var navAgent : NavigationAgent3D = $NavigationAgent3D

var rotateLeft : bool = false
var rotateRight : bool = false

var targetNodeList : Array[TargetNodeText]

func _ready() -> void:
	navAgent.target_position = global_position

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if rotateLeft:
		rotate_y(ROTATE_SPEED)
	if rotateRight:
		rotate_y(-ROTATE_SPEED)
	
	if (navAgent.target_position - global_position).length_squared() > .1:
		move_to_location()
	else:
		velocity = velocity.y * Vector3.UP
	
	move_and_slide()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_left"):
		rotateLeft = true
	if event.is_action_pressed("rotate_right"):
		rotateRight = true
	if event.is_action_released("rotate_left") or event.is_action_released("rotate_right"):
		rotateLeft = false
		rotateRight = false

func move_to_location():
	var direction : Vector3 = (navAgent.get_next_path_position() - global_position).normalized()
	velocity = direction * SPEED




func _on_movement_zone_target_found(location: TargetNodeText) -> void:
	#could add a check here for not allowing seeing spots through walls. Maybe a raycast of some sort
	targetNodeList.append(location)


func _on_movement_zone_target_lost(location: TargetNodeText) -> void:
	targetNodeList.erase(location)
