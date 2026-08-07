extends CanvasLayer

const PHONE_HEIGHT_RATIO := 0.80
const PHONE_MARGIN := 24.0
const PHONE_ASPECT_RATIO := 0.5

@onready var overlay: ColorRect = $overlay
@onready var container: Control = $phone_container
@onready var frame: TextureRect = $phone_container/phone_frame

var opened := false
var phone_size := Vector2.ZERO

func _ready():
	#print("------------------------------")
	#print("PHONE READY")
	#print("------------------------------")
	hide()

	overlay.color.a = 0.0

	#print(frame.size)
	frame.size = Vector2(1000, 1000)
	#print(frame.size)

	update_phone_layout()

func toggle():

	#print("")
	#print("========== TOGGLE ==========")
	#print("Estado abierto:", opened)

	if opened:
		#print("Llamando close_phone()")
		close_phone()
	else:
		#print("Llamando open_phone()")
		open_phone()

func update_phone_layout():
	#print("")
	#print("---- update_phone_layout ----")
	var viewport = get_viewport().get_visible_rect().size
	#print("Viewport:", viewport)
	var height = viewport.y * PHONE_HEIGHT_RATIO
	var width = height * PHONE_ASPECT_RATIO

	phone_size = Vector2(width, height)

	#print("Phone Size:", phone_size)

	container.size = phone_size
	frame.size = phone_size

	container.position = Vector2(
		viewport.x,
		(viewport.y - height) / 2.0
	)

	#print("Container Position:", container.position)
	#print("-----------------------------")

func open_phone():
	#print("")
	#print("***** OPEN PHONE *****")
	show()
	#print("CanvasLayer visible:", visible)
	update_phone_layout()

	var viewport = get_viewport().get_visible_rect().size
	var target = Vector2(
		viewport.x - phone_size.x - PHONE_MARGIN,
		(viewport.y - phone_size.y) / 2.0
	)
	#print("Target:", target)
	var tween = create_tween()

	#print("Tween creado")

	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		container,
		"position",
		target,
		0.25
	)
	#print("Tween Position agregado")
	tween.tween_property(
		overlay,
		"color:a",
		0.45,
		0.25
	)
	#print("Tween Overlay agregado")

	await tween.finished

	#print("Tween TERMINADO")
	#print("Nueva posición:", container.position)

	opened = true

	#print("OPENED =", opened)
	#print("***********************")

func close_phone():
	#print("")
	#print("***** CLOSE PHONE *****")
	var viewport = get_viewport().get_visible_rect().size
	var tween = create_tween()

	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		container,
		"position",
		Vector2(
			viewport.x,
			container.position.y
		),
		0.20
	)
	tween.tween_property(
		overlay,
		"color:a",
		0.0,
		0.20
	)

	await tween.finished
	#print("Tween cerrado")

	hide()

	opened = false
	#print("***********************")

func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		#print("Resize detectado")
		update_phone_layout()
