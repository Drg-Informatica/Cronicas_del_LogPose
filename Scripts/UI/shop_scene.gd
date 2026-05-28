extends Node

const PRECIO_COMPRA: int = 75
const PRECIO_ELIMINAR: int = 50
const PRECIO_RELIQUIAS: int = 150
const CARTAS_EN_TIENDA: int = 2

@onready var lbl_oro: Label = find_child("LblOro", true, false)
@onready var contenedor_comprar: HBoxContainer = find_child("ContenedorCompra", true, false)
@onready var contenerdor_reliquias: VBoxContainer = find_child("ContenedorReliquias", true, false)
@onready var contenerdor_eliminar: HBoxContainer = find_child("ContenedorEliminar", true, false)
@onready var btn_salir: Button = find_child("BtnSalir", true, false)

var pool_tienda: Array[CardData] = []


func _ready() -> void:
	if lbl_oro == null:
		push_error("[SHOP] LblOro no encontrado")
		return
	if contenedor_comprar == null:
		push_error("[SHOP] ContenedorCompra no encontrado")
		return
	if contenerdor_reliquias == null:
		push_error("[SHOP] ContenedorReliquias no encontrado")
		return
	if contenerdor_eliminar == null:
		push_error("[SHOP] ContenedorEliminar no encontrado")
		return
	if btn_salir == null:
		push_error("[SHOP] BtnSalir no encontrado")
		return
	
	btn_salir.pressed.connect(_salir)
	pool_tienda = _cargar_todos_las_cartas()
	pool_tienda.shuffle()
	_mostrar_cartas_compra()
	_mostrar_cartas_eliminar()
	_cargar_reliquias_venta()
	_actualizar_oro()


func _cargar_todos_las_cartas() -> Array[CardData]:
	var cartas: Array[CardData] = []
	var subcarpetas = ["Furia", "Coloso", "Deriva", "Dominacion"]
	for sub in subcarpetas:
		var ruta_carpeta = "res://Resources/Cards/" + sub + "/"
		var dir = DirAccess.open(ruta_carpeta)
		if dir == null:
			continue
		dir.list_dir_begin()
		var archivo = dir.get_next()
		while archivo != "":
			if archivo.ends_with(".tres"):
				var carta = load(ruta_carpeta + archivo) as CardData
				if carta:
					cartas.append(carta)
			archivo = dir.get_next()
	return GameState.get_cartas_recompensa_disponible(cartas)


func _mostrar_cartas_compra() -> void:
	for child in contenedor_comprar.get_children():
		child.queue_free()
	var disponibles = pool_tienda.slice(0, CARTAS_EN_TIENDA)
	for carta in disponibles:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(140, 180)
		btn.text = carta.nombre + "\n\n" + carta.descripcion + "\n\n🪙 " + str(PRECIO_COMPRA)
		btn.pressed.connect(func(): _comprar_carta(carta, btn))
		contenedor_comprar.add_child(btn)


func _mostrar_cartas_eliminar() -> void:
	# Limpiar SOLO el contenedor de eliminar (no el de comprar)
	for child in contenerdor_eliminar.get_children():
		child.queue_free()
	for carta in GameState.mazo_coleccion:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 50)
		btn.text = carta.nombre + "  (🪙 " + str(PRECIO_ELIMINAR) + ")"
		btn.pressed.connect(func(): _eliminar_carta(carta, btn))
		contenerdor_eliminar.add_child(btn)


func _comprar_carta(carta: CardData, btn: Button) -> void:
	if GameState.oro < PRECIO_COMPRA:
		return
	GameState.oro -= PRECIO_COMPRA
	GameState.mazo_coleccion.append(GameState.duplicar_carta(carta))
	btn.disabled = true
	btn.text = "COMPRADA"
	_mostrar_cartas_eliminar()
	_actualizar_oro()


func _eliminar_carta(carta: CardData, btn: Button) -> void:
	if GameState.oro < PRECIO_ELIMINAR:
		return
	GameState.oro -= PRECIO_ELIMINAR        # ← era '=', ahora '-='
	GameState.mazo_coleccion.erase(carta)
	btn.queue_free()
	_actualizar_oro()


func _actualizar_oro() -> void:
	lbl_oro.text = "🪙 " + str(GameState.oro)


func _cargar_reliquias_venta() -> void:
	# Pool de reliquias disponibles, filtrando las que ya tienes
	var todas = [
		RelicData.crear_amuleto_de_coral(),
		RelicData.crear_espueala_de_capitan(),
		RelicData.crear_fragmento_poneglyph(),
	]
	var disponibles: Array = []
	for r in todas:
		var ya_tenida = false
		for r2 in GameState.reliquias:
			if r2.nombre == r.nombre:
				ya_tenida = true
				break
		if not ya_tenida:
			disponibles.append(r)
	
	if disponibles.is_empty():
		return
	
	# Ofrece una reliquia aleatoria
	disponibles.shuffle()
	var reliquia = disponibles[0]
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(200, 80)
	btn.text = reliquia.nombre + "\n\n" + reliquia.descripcion + "\n\n🪙 " + str(PRECIO_RELIQUIAS)
	contenerdor_reliquias.add_child(btn)
	btn.pressed.connect(func(): _comprar_reliquia(reliquia, btn))


func _comprar_reliquia(reliquia: RelicData, btn: Button) -> void:
	if GameState.oro < PRECIO_RELIQUIAS:
		return
	GameState.oro -= PRECIO_RELIQUIAS
	GameState.ganar_reliquia(reliquia.duplicate())
	btn.disabled = true
	btn.text = "COMPRADA"
	_actualizar_oro()


func _salir() -> void:
	if GameState.nodo_actual != null:
		GameState.nodo_actual.completado = true
	GameState.guardar_run()
	_cambiar_escena_diferido.call_deferred("res://Scenes/Map/MapScene.tscn")


func _cambiar_escena_diferido(ruta: String) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		tree.change_scene_to_file(ruta)
	else:
		push_error("No se pudo obtener SceneTree")
