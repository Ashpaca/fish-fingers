class_name TypingAgent extends Node2D

const A : int = 65
const Z : int = 90
const BACKSPACE : int = 4194308
const SPACE : int = 32
const LOWERCASE_OFFSET : int = 32

signal letter_typed

@onready var textDisplay : Label = $Label

func _ready() -> void:
	clear_text_display()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode >= A and event.keycode <= Z:
			textDisplay.text += String.chr(event.keycode + LOWERCASE_OFFSET)
		elif event.keycode == BACKSPACE and len(textDisplay.text) > 0:
			textDisplay.text = textDisplay.text.erase(len(textDisplay.text) - 1)
		elif event.keycode == SPACE and len(textDisplay.text) > 0:
			textDisplay.text += " "
		letter_typed.emit()


func set_text_color(color : String) -> void:
	textDisplay.label_settings.font_color = color
	

func clear_text_display() -> void:
	textDisplay.text = ""
