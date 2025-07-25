class_name RichLabel3D extends Sprite3D

@export var labelWidth : int
@export var labelHeight : int
@export var fontSize : int
@export var outlineSize : int
@export var text : String

@onready var subViewport: SubViewport = $SubViewport
@onready var richTextLabel: RichTextLabel = $SubViewport/RichTextLabel

var numberOfMatchingLetters : int = 0
var totalTypedLetters : int = 0
var startingLettersSkipped : int = 0

func _process(delta: float) -> void:
	setup_text()


func setup_text() -> void:
	richTextLabel.size = Vector2(labelWidth, labelHeight)
	subViewport.size = Vector2(labelWidth, labelHeight)
	var displayedMessage = "[center]" + "[outline_size=" + str(outlineSize) + "]" + "[font_size=" + str(fontSize) + "]"
	
	for i in range(len(text)):
		if i < startingLettersSkipped:
			displayedMessage += "[color=gray]" + text[i] + "[/color]"
		elif i < numberOfMatchingLetters + startingLettersSkipped:
			displayedMessage += "[color=white]" + text[i] + "[/color]"
		elif i < totalTypedLetters + startingLettersSkipped:
			displayedMessage += "[color=red]" + text[i] + "[/color]"
		else:
			displayedMessage += "[color=gray]" + text[i] + "[/color]"
	
	displayedMessage +=   "[/font_size]" + "[/outline_size]" + "[/center]"
	
	richTextLabel.text = displayedMessage


func matched_letters(matchedCount : int, totalCount : int, skipLetters : int = 0) -> void:
	numberOfMatchingLetters = matchedCount
	totalTypedLetters = totalCount
	startingLettersSkipped = skipLetters
