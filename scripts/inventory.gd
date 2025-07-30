class_name Inventory extends Node2D

var icons : Dictionary
var storedFish : Array[Sprite2D]

func _ready() -> void:
	icons["perch"] = "res://UI/Sprites/Angelfish.png"
	icons["trout"] = "res://UI/Sprites/Rainbow Trout.png"
	icons["carp"] = "res://UI/Sprites/Goldfish.png"


func _process(delta: float) -> void:
	pass


func add_fish(fishName : String) -> void:
	var newFish : Sprite2D = Sprite2D.new()
	add_child(newFish)
	newFish.texture = load(icons[fishName])
	newFish.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	newFish.scale = Vector2(4, 4)
	newFish.position = Vector2(32 + len(storedFish)%((1280 - 32)/64) * 64, 32 + floor(len(storedFish)/((1280 - 32)/64)) * 64)
	storedFish.append(newFish)
