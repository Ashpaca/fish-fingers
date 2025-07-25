extends Node3D

const ALL_CHARACTERS : String = "qwertyuiopasdfghjklzxcvbnm"
const MOVE_TEXT_LENGTH : int = 3
const MOVE_STATE : int = 1
const LURE_STATE : int = 2
const REEL_STATE : int = 3

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
		
	

func add_text_nodes():
	for i in range(len(targetNodePositions)):
		var targetNodeTextInstance : TargetNodeText = targetNodeTextScene.instantiate()
		get_tree().root.add_child(targetNodeTextInstance)
		targetNodesTextList.append(targetNodeTextInstance)
		targetNodeTextInstance.global_position = targetNodePositions[i]
		var label : Label3D = targetNodeTextInstance.textBox
		var usedStartingLetters : String = ""
		for j in range(i - 1, -1, -1):
			if (targetNodesTextList[j].global_position - targetNodeTextInstance.global_position).length_squared() < 100: # should be 144, but that might be impossible not to get any doubles
				usedStartingLetters += targetNodesTextList[j].textBox.text[0]
		label.text = ALL_CHARACTERS[randi_range(0, ALL_CHARACTERS.length() - 1)]
		while label.text[0] in usedStartingLetters and len(usedStartingLetters) < len(ALL_CHARACTERS):
			label.text = ALL_CHARACTERS[randi_range(0, ALL_CHARACTERS.length() - 1)]
		for _x in range(MOVE_TEXT_LENGTH - 1):
			label.text += ALL_CHARACTERS[randi_range(0, ALL_CHARACTERS.length() - 1)]



func _on_typing_agent_letter_typed() -> void:
	match currentState:
		MOVE_STATE:
			if len(typingAgent.textDisplay.text) < 1:
				return
			if player.find_partial_match(typingAgent.textDisplay.text):
				typingAgent.set_text_color("white")
			else:
				typingAgent.set_text_color("red")
	
			if player.find_word_match(typingAgent.textDisplay.text):
				typingAgent.clear_text_display()
		
		LURE_STATE:
			if Input.is_action_just_pressed("menu_exit"):
				player.stop_fishing_camera()
				typingAgent.clear_text_display()
				currentState = MOVE_STATE
				currentFishingNode.stop_luring()
			if len(typingAgent.textDisplay.text) < 1:
				return
			if len(typingAgent.textDisplay.text) > 1:
				typingAgent.textDisplay.text = typingAgent.textDisplay.text[0]
			if currentFishingNode.find_fish_QTE(typingAgent.textDisplay.text):
				start_reel_state(currentFishingNode.allActiveFish[currentFishingNode.currentFishID])
			typingAgent.clear_text_display()
		
		REEL_STATE:
			if Input.is_action_just_pressed("menu_exit"):
				player.return_to_fishing_camera(currentFishingNode)
				currentFishingNode.start_luring()
				currentFish.cancel_reel_typing()
				typingAgent.clear_text_display()
				currentState = LURE_STATE
				
			if len(typingAgent.textDisplay.text) < 1:
				return
			if currentFish.find_partial_match(typingAgent.textDisplay.text):
				typingAgent.set_text_color("white")
			else:
				typingAgent.set_text_color("red")
			if currentFish.find_word_match(typingAgent.textDisplay.text):
				typingAgent.clear_text_display()
			
			if currentFish.has_no_words():
				currentFishingNode.remove_fish(currentFish)
				player.return_to_fishing_camera(currentFishingNode)
				currentFishingNode.start_luring()
				typingAgent.clear_text_display()
				currentState = LURE_STATE

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
