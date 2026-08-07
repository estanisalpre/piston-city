extends Resource
class_name GameState

signal money_changed(amount: int)

@export var money := 50000:
	set(value):
		money = value
		money_changed.emit(money)

@export var owned_vehicles : Array[String] = []

@export var selected_vehicle := ""

@export var day := 1

@export var time_of_day := 480.0
