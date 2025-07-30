class_name  Fish extends CharacterBody3D

signal QTE_ended(success : bool)
signal fish_escaped

const ALL_CHARACTERS : String = "qwertyuiopasdfghjklzxcvbnm"
const MIN_QTE_FRAME_COUNT : int = 4
const MAX_QTE_FRAME_COUNT : int = 6
const MAX_PATHING_ATTEMPTS : int = 20
const MAX_PATHING_TIME : float = 5.0

@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
var fishModel : FishInfo = null
@onready var lureLabel : Label3D = $FishCollider/LuringText
@onready var bubbleQTE : AnimatedSprite3D = $FishCollider/LuringText/BubbleSprite
@onready var reelLabel : RichLabel3D = $FishCollider/ReelingText
@onready var sfx_drop: AudioStreamPlayer3D = $SFXDrop
@onready var sfx_wiggle: AudioStreamPlayer3D = $SFXWiggle
@onready var cameraAttachPoint: Node3D = $FishCollider/CameraAttachPoint

# not consts as they are set by the fish type, but they act like consts in this script
var REELING_IN_TIME : float = 2.0    
var FISH_ESCAPE_TIME : float = 4.0
var HOME_LOCATION : Vector3 = Vector3.ZERO
var DESPAWN_LOCATION : Vector3 = Vector3.ZERO
var HOME_RADIUS : float = 4
var TIME_TO_LEAVE : float = -1
var WORD_LENGTHS : Array[int] = [5, 5, 5]


var reeling : bool = false
var swimming : bool = false
var rotationGoal : float = 0.0
var maxSwimHeight : float = 1.5
var swimHeight : float = 0.0
var frameCountQTE : int = 0
var pathingTimer : float = 0.0
var reelingTimer : float = 0.0
var lifetime : float = 0.0

var words : Array[String] = ["", "", ""]

func _ready() -> void:
	navAgent.target_position = global_position
	lureLabel.visible = false
	reelLabel.visible = false

func _physics_process(delta: float) -> void:
	lifetime += delta
	if fishModel == null:
		return
	
	if reeling:
		reelingTimer += delta
		if reelingTimer > FISH_ESCAPE_TIME:
			fish_escaped.emit()
			sfx_wiggle.stop()
			return
		if reelingTimer > REELING_IN_TIME:
			rotate_y(0.1 * sin(reelingTimer * 10))
			if not sfx_wiggle.playing:
				sfx_wiggle.play(3.0)
			return
		else:
			var direction : Vector3 = (navAgent.get_next_path_position() - global_position).normalized()
			var distanceToGo : float = (navAgent.get_final_position() - global_position).length()
			if distanceToGo > .7: #why this number? `\_ツ_/`
				rotationGoal = atan2(direction.x, direction.z) - PI
				velocity = direction * distanceToGo / number_of_words_remaining() / REELING_IN_TIME
				rotate_fish_model(delta)
				fishModel.position = fishModel.position.lerp(Vector3.UP * maxSwimHeight, 0.01)
				move_and_slide()
		return
	if not swimming:
		navAgent.target_position = get_random_spot()
		var pathingAttempts : int = 0
		while !navAgent.is_target_reachable() and pathingAttempts < MAX_PATHING_ATTEMPTS:
			navAgent.target_position = get_random_spot()
			pathingAttempts += 1
		swimHeight = randf_range(0, maxSwimHeight)
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


func get_random_spot() -> Vector3:
	if TIME_TO_LEAVE > 0:
		if lifetime > 4 * TIME_TO_LEAVE:
			return DESPAWN_LOCATION																			# get out of here
		if lifetime > TIME_TO_LEAVE:
			var despawnishDirection : Vector3 = global_position
			if  global_position.x < DESPAWN_LOCATION.x:
				despawnishDirection += Vector3.RIGHT * randf_range(-2, 5)
			else:
				despawnishDirection += Vector3.RIGHT * randf_range(-5, 2)
			if global_position.z < DESPAWN_LOCATION.z:
				despawnishDirection += Vector3.FORWARD * randf_range(-2, 5)
			else:
				despawnishDirection += Vector3.FORWARD * randf_range(-5, 2)
			return despawnishDirection																		# start leaving
	if (global_position - HOME_LOCATION).length() < HOME_RADIUS:
		return global_position + Vector3.RIGHT * randf_range(-5, 5) + Vector3.FORWARD * randf_range(-5, 5)	# free swimming
	var homishDirection : Vector3 = global_position
	if global_position.x < HOME_LOCATION.x:
		homishDirection += Vector3.RIGHT * randf_range(-2, 5)
	else:
		homishDirection += Vector3.RIGHT * randf_range(-5, 2)
	if global_position.z < HOME_LOCATION.z:
		homishDirection += Vector3.FORWARD * randf_range(-2, 5)
	else:
		homishDirection += Vector3.FORWARD * randf_range(-5, 2)
	return homishDirection																					# find home


func setup_fish(info : FishInfo, homeLoc : Vector3, despawnLoc : Vector3) -> void:
	var tempFishModel : Node3D = $FishCollider
	add_child(info)
	info.rotation.x = -PI/2
	for child in tempFishModel.get_children():
		child.reparent(info)
	tempFishModel.queue_free()
	fishModel = info
	REELING_IN_TIME = info.REELING_IN_TIME
	FISH_ESCAPE_TIME = info.FISH_ESCAPE_TIME
	HOME_RADIUS = info.HOME_RADIUS
	TIME_TO_LEAVE = info.TIME_TO_LEAVE
	HOME_LOCATION = homeLoc
	DESPAWN_LOCATION = despawnLoc
	WORD_LENGTHS = info.WORD_LENGTHS
	words.clear()
	for length in WORD_LENGTHS:
		words.append("")
	# other values set here too


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
	swimming = false
	QTE_ended.emit(success)


func _on_bubble_sprite_frame_changed() -> void:
	frameCountQTE += 1


func _on_bubble_sprite_animation_finished() -> void:
	stop_lure_QTE(false)


func check_typed_letter(typedLetter : String) -> bool:
	var success : bool = typedLetter == lureLabel.text and frameCountQTE >= MIN_QTE_FRAME_COUNT and frameCountQTE <= MAX_QTE_FRAME_COUNT
	stop_lure_QTE(success)
	if success:
		sfx_drop.play()
	return success


func start_reel_typing(playerLocation : Vector3) -> void: # could add differnt length words for different fish
	reeling = true
	reelLabel.visible = true
	reelingTimer = 0.0
	if has_no_words():
		for i in range(len(words)):
			match WORD_LENGTHS[i]:
				4:
					words[i] = Main.ALL_WORDS_LENGTH_4.pick_random()
				5:
					words[i] = Main.ALL_WORDS_LENGTH_5.pick_random()
				6:
					words[i] = Main.ALL_WORDS_LENGTH_6.pick_random()
				7:
					words[i] = Main.ALL_WORDS_LENGTH_7.pick_random()
				_:
					words[i] = Main.ALL_WORDS_LENGTH_5.pick_random()
	update_reel_label()
	navAgent.target_position = playerLocation
	

func cancel_reel_typing() -> void:
	reeling = false
	reelLabel.visible = false
	reelLabel.matched_letters(0, 0)
	sfx_wiggle.stop()


func find_partial_match(typedString : String) -> int:
	reelLabel.matched_letters(0, 0)
		
	for i in range(len(typedString), 0, -1):
		for w in range(len(words)):
			if words[w].find(typedString.substr(0, i)) == 0:
				var lettersToSkip = 0
				for m in range(0, w):
					lettersToSkip += len(words[m]) + 1
				reelLabel.matched_letters(i, min(len(words[w]), len(typedString)), lettersToSkip)
				return i
	return 0



func find_word_match(typedString : String) -> bool:
	for i in range(len(words)):
		if words[i] == typedString:
			words[i] = ""
			update_reel_label()
			reelingTimer = 0.0
			sfx_wiggle.stop()
			return true
	return false


func number_of_words_remaining() -> int:
	var remaining : int = 0
	for word in words:
		if word != "":
			remaining += 1
	return remaining


func has_no_words() -> bool:
	for word in words:
		if word != "":
			return false
	return true


func update_reel_label() -> void:
	reelLabel.text = ""
	reelLabel.matched_letters(0, 0)
	for word in words:
		reelLabel.text += word + "\n"
