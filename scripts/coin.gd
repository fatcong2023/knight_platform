extends Area2D

func _ready():
	print("preparing coin")
	connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(body: Node2D) -> void:
	print("this is a coin")
	if body is Player:
		print("i picked up a coin !")
