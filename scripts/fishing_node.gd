class_name FishingNode extends TargetNodeText

const WAIT_TIME_BETWEEN_BITES : float = 1
const CHANCE_FOR_BITE : float = 0.2

signal a_fish_escaped

@export var cameraRotation : Vector3

var allActiveFish : Array[Fish]
var isLuring : bool = false
var biteTimer : float = 0
var currentFishID : int = -1

func _ready() -> void:
	super._ready()
	textBox.text = "start fishing"
	for child in get_children():
		if child is Fish:
			allActiveFish.append(child)
	for fish in allActiveFish:
		fish.connect("QTE_ended", on_fish_QTE_end)
		fish.connect("fish_escaped", on_fish_escaped)


func _physics_process(delta: float) -> void:
	if isLuring:
		handle_fish_biting(delta)


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


func remove_fish(fish : Fish) -> void:
	allActiveFish.erase(fish)
	fish.queue_free()
