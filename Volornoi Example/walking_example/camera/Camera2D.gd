extends Camera2D
@export var MOVE_SPEED : int = 300

func _process(delta):
	if Input.is_action_pressed("ui_left"):
		global_position += Vector2.LEFT * delta * MOVE_SPEED
	if Input.is_action_pressed("ui_right"):
		global_position += Vector2.RIGHT * delta * MOVE_SPEED
	if Input.is_action_pressed("ui_up"):
		global_position += Vector2.UP * delta * MOVE_SPEED
	if Input.is_action_pressed("ui_down"):
		global_position += Vector2.DOWN * delta * MOVE_SPEED
