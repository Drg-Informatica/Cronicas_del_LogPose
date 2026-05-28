class_name Map_Scene
extends Node2D

const SCENE_NODO = preload("res://Scenes/Map/MapNodeUI.tscn")
const COLOR_LINEA = Color(0.4, 0.6, 0.8, 0.5)
const FONDOS_POR_BIOMA: Dictionary = {1: "calma", 2: "grises", 3: "abismo"}

@onready var contenedor_nodos: Node2D = $ContenedorNodos
@onready var lbl_vida: Label = $CanvasLayer/LblVida
@onready var lbl_oro: Label = $CanvasLayer/LblOro

var todos_los_nodos: Array = []
var _cambiando_escena: bool = false


func _ready() -> void:
	if GameState.llegando_de_jefe:
		GameState.aplicar_reliquias_inicio_bioma()
		GameState.llegando_de_jefe = false
		GameState.bioma_actual += 1
		GameState.todos_los_nodos_mapa = []
	
	_actualizar_hud()
	
	if GameState.todos_los_nodos_mapa.is_empty():
		var generador = MapGenerator.new()
		GameState.todos_los_nodos_mapa = generador.generar(GameState.bioma_actual)
	
	todos_los_nodos = GameState.todos_los_nodos_mapa
	_instanciar_nodos()
	
	# Cámara centrada en el mapa
	$Camera2D.zoom = Vector2(0.8, 0.8)
	var altura_mapa = (MapGenerator.CAPAS_POR_BIOMA - 1) * MapGenerator.SEPARACION_Y
	$Camera2D.position = Vector2(0, -altura_mapa / 2.0)
	
	_actualizar_nodos_accesibles()


func _instanciar_nodos() -> void:
	for datos_nodo in todos_los_nodos:
		var nodo_ui: MapNodeUI = SCENE_NODO.instantiate()
		nodo_ui.datos = datos_nodo
		nodo_ui.position = datos_nodo.posicion
		nodo_ui.nodo_pulsado.connect(_on_nodo_pulsado)
		contenedor_nodos.add_child(nodo_ui)
	queue_redraw()


func _draw() -> void:
	for datos_nodo in todos_los_nodos:
		for siguiente in datos_nodo.nodos_siguientes:
			draw_line(datos_nodo.posicion, siguiente.posicion, COLOR_LINEA, 2.0)


func _actualizar_nodos_accesibles() -> void:
	var algun_completado = false
	for nodo in todos_los_nodos:
		if nodo.completado:
			algun_completado = true
			break
	
	var accesibles: Array = []
	if not algun_completado:
		# Primera capa (capa 0): los nodos con y == 0
		for nodo in todos_los_nodos:
			if nodo.posicion.y == 0:
				accesibles.append(nodo)
	else:
		# Hijos directos del último nodo pulsado
		if GameState.nodo_actual != null:
			for siguiente in GameState.nodo_actual.nodos_siguientes:
				accesibles.append(siguiente)
	
	for hijo in contenedor_nodos.get_children():
		if hijo is MapNodeUI:
			hijo.set_accesible(hijo.datos in accesibles)


func _on_nodo_pulsado(datos: MapNodeData) -> void:
	if _cambiando_escena:
		return
	if datos.completado:
		return
	
	_cambiando_escena = true
	
	GameState.nodo_actual = datos
	GameState.fondo_combate_actual = FONDOS_POR_BIOMA.get(datos.bioma, "ocean")
	
	var ruta_destino: String = ""
	match datos.tipo:
		MapNodeData.TipoNodo.COMBATE, MapNodeData.TipoNodo.ELITE, MapNodeData.TipoNodo.JEFE:
			ruta_destino = "res://Scenes/Combat/CombatScene.tscn"
		MapNodeData.TipoNodo.TIENDA:
			ruta_destino = "res://Scenes/UI/ShopScene.tscn"
		MapNodeData.TipoNodo.NOCHE_CABINA:
			ruta_destino = "res://Scenes/UI/NocheCabinaScene.tscn"
		MapNodeData.TipoNodo.EVENTO:
			ruta_destino = "res://Scenes/UI/EventScene.tscn"
	
	if ruta_destino.is_empty():
		push_warning("Tipo de nodo sin ruta: " + str(datos.tipo))
		_cambiando_escena = false
		return
	
	if not ResourceLoader.exists(ruta_destino):
		push_error("Escena no existe: " + ruta_destino)
		_cambiando_escena = false
		return
	
	_cambiar_escena_diferido.call_deferred(ruta_destino)


func _cambiar_escena_diferido(ruta: String) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		tree.change_scene_to_file(ruta)
	else:
		push_error("No se pudo obtener SceneTree")


func _actualizar_hud() -> void:
	lbl_vida.text = "❤ " + str(GameState.vida_capitan) + " / " + str(GameState.vida_maxima_capitan)
	lbl_oro.text = "🪙 " + str(GameState.oro)
