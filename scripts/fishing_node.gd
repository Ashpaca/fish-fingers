class_name FishingNode extends TargetNodeText

const WAIT_TIME_BETWEEN_BITES : float = 1
const CHANCE_FOR_BITE : float = 0.2

signal a_fish_escaped

@export var cameraRotation : Vector3
@export var waterDepth : float
@export var maxFishCount : int
@export var fishSpawnTime : float
@export var spawnPoint : Node3D
@export var despawnPoint : Node3D
@export var fishTypes : Array[PackedScene]

@onready var sfx_catch_fish: AudioStreamPlayer3D = $SFXCatchFish

var fishTemplateScene : PackedScene = load("res://scenes/fish_template.tscn")
var allActiveFish : Array[Fish]
var isLuring : bool = false
var biteTimer : float = 0.0
var currentFishID : int = -1

var spawnTimer : float = 0.0

func _ready() -> void:
	super._ready()
	textBox.text = "start fishing"
	for child in get_children():
		if child is Fish:
			allActiveFish.append(child)
	for fish in allActiveFish:
		fish.connect("QTE_ended", on_fish_QTE_end)
		fish.connect("fish_escaped", on_fish_escaped)
		fish.maxSwimHeight = waterDepth - 1
		fish.setup_fish(fishTypes.pick_random().instantiate(), global_position + Vector3.DOWN * waterDepth, despawnPoint.global_position)
		


func _physics_process(delta: float) -> void:
	if isLuring:
		handle_fish_biting(delta)
	spawnTimer += delta
	if spawnTimer > fishSpawnTime and len(allActiveFish) < maxFishCount:
		spawnTimer = 0.0
		var newFish : Fish = fishTemplateScene.instantiate()
		add_child(newFish)
		allActiveFish.append(newFish)
		newFish.position = spawnPoint.position
		newFish.connect("QTE_ended", on_fish_QTE_end)
		newFish.connect("fish_escaped", on_fish_escaped)
		newFish.maxSwimHeight = waterDepth - 1
		newFish.setup_fish(fishTypes.pick_random().instantiate(), global_position + Vector3.DOWN * waterDepth, despawnPoint.global_position)
	
	for fish in allActiveFish:
		if not fish.reeling and fish.global_position.distance_to(despawnPoint.global_position) < 1:
			remove_fish(fish)
		

func start_luring() -> void:
	isLuring = true
	biteTimer = 0
	
func stop_luring() -> void:
	isLuring = false
	for fish in allActiveFish:
		fish.lureLabel.visible = false


func find_fish_QTE(typedLetter : String) -> bool:
	if currentFishID < 0:
		return false
	return allActiveFish[currentFishID].check_typed_letter(typedLetter)


func handle_fish_biting(delta: float) -> void:
	if currentFishID > -1 or len(allActiveFish) < 1:
		return
	biteTimer += delta
	if biteTimer < WAIT_TIME_BETWEEN_BITES:
		return
	biteTimer = 0
	if randf() > CHANCE_FOR_BITE:
		return
	currentFishID = randi_range(0, len(allActiveFish) - 1)
	allActiveFish[currentFishID].start_lure_QTE()


func on_fish_QTE_end(success : bool) -> void:
	if not success:
		currentFishID = -1


func on_fish_escaped() -> void:
	a_fish_escaped.emit()


func catch_and_remove_fish(fish : Fish) -> void:
	sfx_catch_fish.play(0.4)
	remove_fish(fish)


func remove_fish(fish : Fish) -> void:
	allActiveFish.erase(fish)
	fish.queue_free()
