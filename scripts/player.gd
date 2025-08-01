class_name Player extends CharacterBody3D

const SPEED = 2.5
const ROTATE_SPEED = 0.03
const LERP_TO_FISH_SPEED : float = 3
const LERP_TO_MOVE_SPEED : float = 5

signal start_fishing(node : FishingNode)

@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var playerModel : Node3D = $Cat
@onready var playerAnimator : AnimationPlayer = $Cat/AnimationPlayer
@onready var cameraPivot : Node3D = $CameraPivot
@onready var camera : Camera3D = $CameraPivot/CameraLocation/Camera3D
@onready var cameraSightRay : RayCast3D = $CameraPivot/CameraLocation/LineOfSight
@onready var sfx_walking_grass: AudioStreamPlayer3D = $SFXWalkingGrass
@onready var fishingRod : Node3D = $Cat/FishingRod
@onready var fishingRodString : Node3D = $Cat/FishingRod/StringStartPoint/String

var rotateLeft : bool = false
var rotateRight : bool = false
var rotationGoal : float = 0.0
var lastSavedCameraRotation : Vector3 = Vector3.ZERO
var cameraLerpSpeed : float = LERP_TO_FISH_SPEED
var targetNodeList : Array[TargetNodeText]
var fishBeingCaught : Fish = null

func _ready() -> void:
	navAgent.target_position = global_position
	playerAnimator.play("cat walk")

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
		if playerAnimator.current_animation == "cat walk":
			playerAnimator.call_deferred("pause")
			sfx_walking_grass.stop()
	
	cameraPivot.position = cameraPivot.position.lerp(Vector3.ZERO, cameraLerpSpeed * delta)
	var obj : Object = cameraSightRay.get_collider()
	if obj and obj.name == "GridMap":
		camera.global_position = cameraSightRay.get_collision_point()
	else:
		camera.position = Vector3.ZERO
	
	if fishBeingCaught:
		drawing_string()
	
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


func stop_walking_early() -> void:
	navAgent.target_position = global_position
	playerAnimator.play("cat lazy idle")
	sfx_walking_grass.stop()


func move_to_location():
	var direction : Vector3 = (navAgent.get_next_path_position() - global_position).normalized()
	rotationGoal = atan2(direction.x, direction.z)
	velocity = direction * SPEED


func find_partial_match(typedString : String) -> int:
	for target in targetNodeList:
		target.textBox.matched_letters(0, 0)
	
	for i in range(len(typedString), 0, -1):
		for target in targetNodeList:
			if target.textBox.text.find(typedString.substr(0, i)) == 0:
				var direction : Vector3 = (target.global_position - global_position).normalized()
				rotationGoal = atan2(direction.x, direction.z)
				target.textBox.matched_letters(i, len(typedString))
				return i
	return 0


func find_word_match(typedString : String) -> bool:
	for target in targetNodeList:
		if target.textBox.text == typedString:
			if target is FishingNode:
				start_fishing.emit(target)
				start_fishing_camera(target)
				playerAnimator.play("cat lazy idle")
				sfx_walking_grass.stop()
			else:
				navAgent.target_position = target.global_position
				playerAnimator.play("cat walk")
				sfx_walking_grass.play(randf_range(0.0, 1.0))
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
	cameraPivot.reparent(node)
	cameraPivot.rotation = node.cameraRotation
	cameraLerpSpeed = LERP_TO_FISH_SPEED
	for target in targetNodeList:
		target.textBox.visible = false
	show_rod(true)


func return_to_fishing_camera(node : FishingNode) -> void:
	cameraPivot.reparent(node)
	cameraPivot.rotation = node.cameraRotation
	cameraLerpSpeed = LERP_TO_FISH_SPEED
	stop_drawing_string_to_fish()
	
func stop_fishing_camera() -> void:
	cameraPivot.reparent(self)
	cameraLerpSpeed = LERP_TO_MOVE_SPEED
	cameraPivot.rotation = lastSavedCameraRotation
	for target in targetNodeList:
		target.textBox.visible = true
	show_rod(false)

func start_catching_camera(fish : Fish) -> void:
	cameraPivot.reparent(fish.cameraAttachPoint)
	cameraPivot.rotation = lastSavedCameraRotation
	cameraPivot.rotate_y(PI)
	start_drawing_string_to_fish(fish)


func show_rod(showHide : bool) -> void:
	fishingRod.visible = showHide


func start_drawing_string_to_fish(fish : Fish):
	fishBeingCaught = fish
	fishingRodString.visible = true


func drawing_string() -> void:
	var stringMesh : CylinderMesh = fishingRodString.get_child(0).mesh
	var fishMeshLocation : Vector3 = fishBeingCaught.fishModel.global_position
	stringMesh.height = (fishingRodString.get_parent_node_3d().global_position - fishMeshLocation).length() * 2
	fishingRodString.look_at(fishMeshLocation)
	fishingRodString.global_position = (fishingRodString.get_parent_node_3d().global_position + fishMeshLocation) / 2


func stop_drawing_string_to_fish() -> void:
	fishBeingCaught = null
	fishingRodString.visible = false
