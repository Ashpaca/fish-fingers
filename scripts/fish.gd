class_name  Fish extends CharacterBody3D

signal QTE_ended(success : bool)

const ALL_CHARACTERS : String = "qwertyuiopasdfghjklzxcvbnm"
const ALL_WORDS : Array[String] = ["aardvark", "because", "college", "dog", "enough", "fish",
								"goober", "hello", "illegal", "juice", "keeping", "llama", 
								"mountain", "noun", "octopus"]
const MIN_QTE_FRAME_COUNT : int = 4
const MAX_QTE_FRAME_COUNT : int = 6
const MAX_PATHING_ATTEMPTS : int = 10
const MAX_PATHING_TIME : float = 5

@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var fishModel : CollisionShape3D = $FishCollider
@onready var lureLabel : Label3D = $FishCollider/LuringText
@onready var bubbleQTE : AnimatedSprite3D = $FishCollider/LuringText/BubbleSprite
@onready var reelLabel : Label3D = $FishCollider/ReelingText
var fishTypes : Array[String] = ["res://scenes/fish_types/fish_1.tscn", "res://scenes/fish_types/fish_2.tscn", "res://scenes/fish_types/fish_3.tscn"]

var reeling : bool = false
var swimming : bool = true
var rotationGoal : float = 0.0
var swimHeight : float = 0.0
var frameCountQTE : int = 0
var pathingTimer : float = 0

var words : Array[String] = ["", "", ""]

func _ready() -> void:
	navAgent.target_position = global_position
	var fishBody : CollisionShape3D = load(fishTypes.pick_random()).instantiate()
	fishModel.shape = fishBody.shape
	fishModel.get_node("FishMesh").mesh = fishBody.get_node("FishMesh").mesh
	lureLabel.visible = false
	reelLabel.visible = false

func _physics_process(delta: float) -> void:
	if reeling:
		#maybe start moving away from player. Typing a word correctly pulls them back?
		return
	
	if not swimming:
		navAgent.target_position = global_position + Vector3.RIGHT * randf_range(-5, 5) + Vector3.FORWARD * randf_range(-5, 5)
		var pathingAttempts : int = 0
		while !navAgent.is_target_reachable() and pathingAttempts < MAX_PATHING_ATTEMPTS:
			navAgent.target_position = global_position + Vector3.RIGHT * randf_range(-5, 5) + Vector3.FORWARD * randf_range(-5, 5)
			pathingAttempts += 1
		swimHeight = randf_range(0, 1.5)
		swimming = true
		pathingTimer = 0.0
	elif (navAgent.target_position - global_position).length_squared() > 1.1:
		var direction : Vector3 = (navAgent.get_next_path_position() - global_position).normalized()
		rotationGoal = atan2(direction.x, direction.z)
		velocity = direction * 1.2
		fishModel.position = fishModel.position.lerp(Vector3.UP * swimHeight, 0.02)
		pathingTimer += delta
		if pathingTimer > MAX_PATHING_TIME:
			swimming = false
	else:
		swimming = false
	
	rotate_fish_model(delta)
	move_and_slide()


func rotate_fish_model(delta : float) -> void:
	var max_angle = PI * 2
	var difference = fmod(rotationGoal - rotation.y, max_angle)
	rotation.y = rotation.y + (fmod(2 * difference, max_angle) - difference) * delta * 3


func start_lure_QTE() -> void:
	lureLabel.visible = true
	lureLabel.text = ALL_CHARACTERS[randi_range(0, ALL_CHARACTERS.length() - 1)]
	frameCountQTE = 0
	bubbleQTE.play("QTE")
	
	
func stop_lure_QTE(success : bool) -> void:
	lureLabel.visible = false
	QTE_ended.emit(success)


func _on_bubble_sprite_frame_changed() -> void:
	frameCountQTE += 1


func _on_bubble_sprite_animation_finished() -> void:
	stop_lure_QTE(false)


func check_typed_letter(typedLetter : String) -> bool:
	var success : bool = typedLetter == lureLabel.text and frameCountQTE >= MIN_QTE_FRAME_COUNT and frameCountQTE <= MAX_QTE_FRAME_COUNT
	stop_lure_QTE(success)
	return success


func start_reel_typing() -> void:
	reeling = true
	reelLabel.visible = true
	if has_no_words():
		for i in range(len(words)):
			words[i] = ALL_WORDS.pick_random()
	update_reel_label()
	

func cancel_reel_typing() -> void:
	reeling = false
	reelLabel.visible = false


func find_partial_match(typedString : String) -> bool:
	for word in words:
		if word.find(typedString) == 0:
			return true
	return false



func find_word_match(typedString : String) -> bool:
	for i in range(len(words)):
		if words[i] == typedString:
			words[i] = ""
			update_reel_label()
			return true
	return false


func has_no_words() -> bool:
	for word in words:
		if word != "":
			return false
	return true


func update_reel_label() -> void:
	reelLabel.text = ""
	for word in words:
		reelLabel.text += word + "\n"
