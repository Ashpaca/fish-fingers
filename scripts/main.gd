extends Node3D

const ALL_CHARACTERS : String = "qwertyuiopasdfghjklzxcvbnm"
const MOVE_TEXT_LENGTH : int = 3

@onready var player : Player = $Player
@onready var targetNodes : GridMap = $MovementMap
@onready var typingAgent : TypingAgent = $TypingAgent
var targetNodeTextScene : PackedScene = load("res://scenes/target_node_text.tscn")

var targetNodePositions : Array[Vector3]
var targetNodesTextList : Array[TargetNodeText]

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


func _physics_process(delta: float) -> void:
	check_for_word_matches()


func check_for_word_matches():
	for target in player.targetNodeList:
		if target.textBox.text == typingAgent.textDisplay.text:
			typingAgent.textDisplay.text = ""
			player.navAgent.target_position = target.global_position
