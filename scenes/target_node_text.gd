class_name TargetNodeText extends Area3D

@onready var textBox : Label3D = $Label3D

func _ready() -> void:
	textBox.visible = false


func _on_area_entered(area: Area3D) -> void:
	if area.name == "MovementZone":
		textBox.visible = true
		area.emit_signal("target_found", self)


func _on_area_exited(area: Area3D) -> void:
	if area.name == "MovementZone":
		textBox.visible = false
		area.emit_signal("target_lost", self)
