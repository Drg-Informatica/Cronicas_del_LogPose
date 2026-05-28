class_name RewardScene
extends Node

@onready var lbl_oro: Label = find_child("LblOro", true, false)
@onready var hbox_cartas: HBoxContainer = find_child("HBoxCartas", true, false)
@onready var btn_saltar: Button = find_child("BtnSaltar", true, false)
@onready var vbox: VBoxContainer = $CanvasLayer/Panel/VBox

const SCENE_CARD_UI = preload("res://Scenes/Card/card_ui.tscn")


func _ready() -> void:
	if lbl_oro == null:
		push_error("[REWARD] LblOro no encontrado en el árbol")
		return
	if hbox_cartas == null:
		push_error("[REWARD] HBoxCartas no encontrado en el árbol")
		return
	if btn_saltar == null:
		push_error("[REWARD] BtnSaltar no encontrado en el árbol")
		return
	if vbox == null:
		push_error("[REWARD] VBox no encontrado en el árbol")
		return
	
	var recompensa = GameState.nodo_actual.datos_extra.get("recompensa", {})
	var oro_ganado = recompensa.get("oro", 0)
	GameState.oro += oro_ganado
	lbl_oro.text = "+" + str(oro_ganado) + " ORO"
	_mostrar_tres_cartas()
	btn_saltar.pressed.connect(_salir)


func _mostrar_tres_cartas() -> void:
	var pool = _cargar_pool_cartas()
	pool.shuffle()
	for i in min(3, pool.size()):
		var carta_ui = SCENE_CARD_UI.instantiate() as CardUI
		carta_ui.en_mano = false        # ← MODO SELECCIÓN
		carta_ui.datos = pool[i]
		hbox_cartas.add_child(carta_ui)
		var datos_cap = pool[i]
		carta_ui.carta_presionada.connect(func(_carta_ui): _elegir_carta(datos_cap))
	if GameState.nodo_actual.tipo in [MapNodeData.TipoNodo.ELITE, MapNodeData.TipoNodo.JEFE]:
		_ofrecer_reliquia()

func _ofrecer_reliquia() -> void:
	var pool = [
		RelicData.crear_espueala_de_capitan(),
		RelicData.crear_fragmento_poneglyph(),
		RelicData.crear_amuleto_de_coral(),
	]
	var disponibles: Array = []
	for r in pool:
		var ya_tenida = false
		for r2 in GameState.reliquias:
			if r2.nombre == r.nombre:
				ya_tenida = true
				break
		if not ya_tenida:
			disponibles.append(r)
	if disponibles.is_empty():
		return
	var elegida = disponibles[randi() % disponibles.size()]
	var btn := Button.new()
	btn.text = "🎁 " + elegida.nombre + " — " + elegida.descripcion
	btn.pressed.connect(func():
		GameState.ganar_reliquia(elegida)
		btn.disabled = true
		btn.text = "✓ Recogida"
	)
	vbox.add_child(btn)   # ← era $CanvasLayer/Panel/VBox.add_child(btn), ahora usa la variable


func _elegir_carta(carta: CardData) -> void:
	GameState.mazo_coleccion.append(GameState.duplicar_carta(carta))
	_salir()


func _cargar_pool_cartas() -> Array[CardData]:
	var esencias_disponibles: Array = []
	if GameState.capitan_actual:
		esencias_disponibles.append(int(GameState.capitan_actual.esencia))
	for miembro in GameState.tripulacion:
		var esencia_idx = int(miembro.esencia_aportada)
		if esencia_idx not in esencias_disponibles:
			esencias_disponibles.append(esencia_idx)
	
	var rareza_minima: int = 0
	match GameState.nodo_actual.tipo:
		MapNodeData.TipoNodo.ELITE:
			rareza_minima = 1
		MapNodeData.TipoNodo.JEFE:
			rareza_minima = 2
	
	var pool: Array[CardData] = []
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
				if carta and int(carta.esencia) in esencias_disponibles and carta.rareza >= rareza_minima:
					pool.append(carta)
			archivo = dir.get_next()
	return pool


func _salir() -> void:
	var era_jefe_final: bool = (
		GameState.nodo_actual != null
		and GameState.nodo_actual.tipo == MapNodeData.TipoNodo.JEFE
		and GameState.nodo_actual.bioma == 3
	)
	
	if era_jefe_final:
		GameState.on_run_completada(true)
		return
	
	if GameState.nodo_actual != null:
		GameState.nodo_actual.completado = true
	
	_cambiar_escena_diferido.call_deferred("res://Scenes/Map/MapScene.tscn")


func _cambiar_escena_diferido(ruta: String) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		tree.change_scene_to_file(ruta)
	else:
		push_error("No se pudo obtener SceneTree")
