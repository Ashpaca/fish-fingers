extends Area3D

signal target_found(loaction: TargetNodeText)
signal target_lost(location: TargetNodeText)

func found(node : TargetNodeText) -> void:
	target_found.emit(node)
	

func lost(node : TargetNodeText) -> void:
	target_lost.emit(node)
