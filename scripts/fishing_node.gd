class_name FishingNode extends TargetNodeText

@export var cameraRotation : Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	textBox.text = "start fishing"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
