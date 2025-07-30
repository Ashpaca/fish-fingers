class_name ScreenEffects extends Node2D

const QTE_ANIMATION_TIME : float = 1.7
const QTE_SLOW_RING_STARTING_SCALE : float = 20
const QTE_FAST_RING_STARTING_SCALE : float = 50

@onready var qteSlowRing: Sprite2D = $QTE_SlowRing
@onready var qteFastRing: Sprite2D = $QTE_FastRing

var qteTimer : float = 0.0
var qteIsActive : bool = false
var qteWorldObject : Label3D
var camera : Camera3D


func _process(delta: float) -> void:
	if qteIsActive:
		handle_QTE_effects(delta)


func start_QTE_effects(labelToFollow : Label3D, sceneCamera : Camera3D) -> void:
	qteIsActive = true
	qteSlowRing.visible = true
	qteFastRing.visible = true
	qteWorldObject = labelToFollow
	camera = sceneCamera
	qteTimer = 0.0


func end_QTE_effects() -> void:
	qteIsActive = false
	qteSlowRing.visible = false
	qteFastRing.visible = false


func handle_QTE_effects(delta : float) -> void:
	qteTimer += delta
	qteFastRing.scale = Vector2(1, 1) * (1 + QTE_FAST_RING_STARTING_SCALE * (1 - sqrt(qteTimer / QTE_ANIMATION_TIME)))
	qteSlowRing.scale = Vector2(1, 1) * (1 + QTE_SLOW_RING_STARTING_SCALE * (1 - sqrt(qteTimer / QTE_ANIMATION_TIME)))
	qteFastRing.position = camera.unproject_position(qteWorldObject.global_position)
	qteSlowRing.position = qteFastRing.position
	if qteTimer > QTE_ANIMATION_TIME:
		end_QTE_effects()
