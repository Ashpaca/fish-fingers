class_name Main extends Node3D

const ALL_CHARACTERS : String = "qwertyuiopasdfghjklzxcvbnm"
const MOVE_TEXT_LENGTH : int = 3
const MOVE_STATE : int = 1
const LURE_STATE : int = 2
const REEL_STATE : int = 3

static var ALL_WORDS_LENGTH_3 : Array[String]
static var ALL_WORDS_LENGTH_4 : Array[String]
static var ALL_WORDS_LENGTH_5 : Array[String]
static var ALL_WORDS_LENGTH_6 : Array[String]
static var ALL_WORDS_LENGTH_7 : Array[String]

@onready var player : Player = $Player
@onready var targetNodes : GridMap = $MovementMap
@onready var typingAgent : TypingAgent = $TypingAgent

var targetNodeTextScene : PackedScene = load("res://scenes/target_node_text.tscn")
var targetNodePositions : Array[Vector3]
var targetNodesTextList : Array[TargetNodeText]
var currentFishingNode : FishingNode
var currentFish : Fish

var currentState = MOVE_STATE

func _ready() -> void:
	for cell in targetNodes.get_used_cells():
		var nodeLocation : Vector3 = Vector3(cell.x + 0.5, cell.y + 0.5, cell.z + 0.5)
		targetNodePositions.append(nodeLocation)
		
	call_deferred("add_text_nodes")
	setup_all_words()

func setup_all_words():
	var allWordsFile : FileAccess = FileAccess.open("res://word_lists/enable1.txt", FileAccess.READ)
	while not allWordsFile.eof_reached():
		var line : String = allWordsFile.get_line()
		match len(line):
			3:
				ALL_WORDS_LENGTH_3.append(line)
			4:
				ALL_WORDS_LENGTH_4.append(line)
			5:
				ALL_WORDS_LENGTH_5.append(line)
			6:
				ALL_WORDS_LENGTH_6.append(line)
			7:
				ALL_WORDS_LENGTH_7.append(line)


func add_text_nodes():
	for i in range(len(targetNodePositions)):
		var targetNodeTextInstance : TargetNodeText = targetNodeTextScene.instantiate()
		get_tree().root.add_child(targetNodeTextInstance)
		targetNodesTextList.append(targetNodeTextInstance)
		targetNodeTextInstance.global_position = targetNodePositions[i]
		var label : RichLabel3D = targetNodeTextInstance.textBox
		var usedWords : Array[String]
		for j in range(i - 1, -1, -1):
			if (targetNodesTextList[j].global_position - targetNodeTextInstance.global_position).length_squared() < 144:
				usedWords.append(targetNodesTextList[j].textBox.text)
		label.text = ALL_WORDS_LENGTH_3[randi_range(0, len(ALL_WORDS_LENGTH_3) - 1)]
		while label.text in usedWords:
			label.text = ALL_WORDS_LENGTH_3[randi_range(0, len(ALL_WORDS_LENGTH_3) - 1)]



func _on_typing_agent_letter_typed() -> void:
	match currentState:
		MOVE_STATE:
			if Input.is_action_just_pressed("menu_exit"):
				player.stop_walking_early()
			typingAgent.set_matching_letters(player.find_partial_match(typingAgent.get_text()))
			if player.find_word_match(typingAgent.get_text()):
				typingAgent.clear_text_display()
		
		LURE_STATE:
			print(typingAgent.get_text())
			if Input.is_action_just_pressed("menu_exit"):
				player.stop_fishing_camera()
				typingAgent.clear_text_display()
				currentState = MOVE_STATE
				currentFishingNode.stop_luring()
			if len(typingAgent.get_text()) < 1:
				return
			if len(typingAgent.get_text()) > 1:
				typingAgent.set_text(typingAgent.get_text()[0])
			if currentFishingNode.find_fish_QTE(typingAgent.get_text()):
				start_reel_state(currentFishingNode.allActiveFish[currentFishingNode.currentFishID])
			typingAgent.clear_text_display()
		
		REEL_STATE:
			if Input.is_action_just_pressed("menu_exit"):
				cancel_reel_state()
				
			#if len(typingAgent.get_text()) < 1:
			#	return
			typingAgent.set_matching_letters(currentFish.find_partial_match(typingAgent.get_text()))
			if currentFish.find_word_match(typingAgent.get_text()):
				typingAgent.clear_text_display()
			
			if currentFish.has_no_words():
				handle_caught_fish()

func _on_player_start_fishing(node : FishingNode) -> void:
	currentState = LURE_STATE
	currentFishingNode = node
	currentFishingNode.start_luring()
	
func start_reel_state(fish : Fish) -> void:
	currentState = REEL_STATE
	currentFishingNode.stop_luring()
	currentFish = fish
	currentFish.start_reel_typing(player.global_position)
	player.start_catching_camera(currentFish)


func cancel_reel_state() -> void:
	player.return_to_fishing_camera(currentFishingNode)
	currentFishingNode.start_luring()
	currentFish.cancel_reel_typing()
	typingAgent.clear_text_display()
	currentState = LURE_STATE

func _on_fishing_node_a_fish_escaped() -> void:
	cancel_reel_state()


func handle_caught_fish() -> void:
	cancel_reel_state()
	currentFishingNode.catch_and_remove_fish(currentFish)
