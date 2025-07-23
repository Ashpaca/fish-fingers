class_name Player extends CharacterBody3D

const SPEED = 2.5
const ROTATE_SPEED = 0.03

signal start_fishing(node : FishingNode)

@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var playerModel : Node3D = $Cat
@onready var cameraPivot : Node3D = $CameraPivot

var rotateLeft : bool = false
var rotateRight : bool = false
var rotationGoal : float = 0.0
var lastSavedCameraRotation : Vector3 = Vector3.ZERO
var targetNodeList : Array[TargetNodeText]

func _ready() -> void:
	navAgent.target_position = global_position

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if rotateLeft:
		cameraPivot.rotate_y(ROTATE_SPEED)
	if rotateRight:
		cameraPivot.rotate_y(-ROTATE_SPEED)
	
	if (navAgent.target_position - global_position).length_squared() > 1.1: # only move to location when further than nav goal
		move_to_location()
	else:
		velocity = velocity.y * Vector3.UP
	
	rotate_player_model(delta)
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
	rotationGoal = atan2(direction.x, direction.z)
	velocity = direction * SPEED


func find_partial_match(typedString : String) -> bool:
	for target in targetNodeList:
		if target.textBox.text.find(typedString) == 0:
			var direction : Vector3 = (target.global_position - global_position).normalized()
			rotationGoal = atan2(direction.x, direction.z)
			return true
	return false


func find_word_match(typedString : String) -> bool:
	for target in targetNodeList:
		if target.textBox.text == typedString:
			if target is FishingNode:
				start_fishing.emit(target)
				start_fishing_camera(target)
			else:
				navAgent.target_position = target.global_position
			return true
	return false


func rotate_player_model(delta : float) -> void:
	var max_angle = PI * 2
	var difference = fmod(rotationGoal - playerModel.rotation.y, max_angle)
	playerModel.rotation.y = playerModel.rotation.y + (fmod(2 * difference, max_angle) - difference) * delta * 3


func _on_movement_zone_target_found(location: TargetNodeText) -> void:
	#could add a check here for not allowing seeing spots through walls. Maybe a raycast of some sort
	targetNodeList.append(location)


func _on_movement_zone_target_lost(location: TargetNodeText) -> void:
	targetNodeList.erase(location)
	
	
func start_fishing_camera(node : FishingNode) -> void:
	lastSavedCameraRotation = cameraPivot.rotation
	cameraPivot.rotation = node.cameraRotation
	cameraPivot.reparent(node)
	cameraPivot.position = Vector3.ZERO
	for target in targetNodeList:
		target.textBox.visible = false
	
	
func stop_fishing_camera() -> void:
	cameraPivot.reparent(self)
	cameraPivot.position = Vector3.ZERO
	cameraPivot.rotation = lastSavedCameraRotation
	for target in targetNodeList:
		target.textBox.visible = true
