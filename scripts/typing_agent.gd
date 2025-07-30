class_name TypingAgent extends Node2D

const A : int = 65
const Z : int = 90
const BACKSPACE : int = 4194308
const SPACE : int = 32
const LOWERCASE_OFFSET : int = 32

signal letter_typed



@onready var textDisplay : RichTextLabel = $RichTextLabel

var numberOfMatchingLetters : int = 0
var fontSize : int = 32
var outlineSize : int = 20
var text : String = ""

func _ready() -> void:
	clear_text_display()


func _process(delta: float) -> void:
	setup_text()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode >= A and event.keycode <= Z:
			text += String.chr(event.keycode + LOWERCASE_OFFSET)
		elif event.keycode == BACKSPACE and len(text) > 0:
			text = text.erase(len(text) - 1)
		elif event.keycode == SPACE and len(text) > 0:
			text += " "
		letter_typed.emit()


func setup_text() -> void:
	var displayedMessage = "[center]" + "[outline_size=" + str(outlineSize) + "]" + "[font_size=" + str(fontSize) + "]"
	
	for i in range(len(text)):
		if i < numberOfMatchingLetters:
			displayedMessage += "[color=white]" + text[i] + "[/color]"
		else:
			displayedMessage += "[color=red]" + text[i] + "[/color]"
	
	displayedMessage +=   "[/font_size]" + "[/outline_size]" + "[/center]"
	
	if numberOfMatchingLetters < len(text):
		displayedMessage = "[shake rate=20.0 level=" + str(4 + len(text) - numberOfMatchingLetters) + " connected=1]" + displayedMessage + "[/shake]"
	
	textDisplay.text = displayedMessage

func set_matching_letters(letterCount : int) -> void:
	numberOfMatchingLetters = letterCount
	

func clear_text_display() -> void:
	text = ""


func get_text() -> String:
	return text


func set_text(newText : String) -> void:
	text = newText
