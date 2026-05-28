extends Node

# Tabla de eventos del juego
const EVENTOS: Array[Dictionary] = [
	{
		"titulo": "El Náufrago",
		"descripcion": "Encuentras a un marinero aferrado a los restos de un barco. Te mira con ojos suplicantes.",
		"opciones": [
			{"texto": "Rescatarlo  →  +50 🪙 pero -10 HP (pierde tiempo)",   "efecto": "rescatar"},
			{"texto": "Dejarlo pasar  →  nada pasa, sigues ruta",             "efecto": "nada"},
		]
	},
	{
		"titulo": "La Tormenta Repentina",
		"descripcion": "Un frente de tormenta aparece sin avisar. Debes decidir cómo actuar antes de que llegue.",
		"opciones": [
			{"texto": "Arriar velas (seguro)  →  -10 HP, +50 🪙",            "efecto": "tormenta_prudente"},
			{"texto": "Resistir a toda vela (arriesgado)  →  50% +20🪙 / 50% -25 HP y +20🪙", "efecto": "tormenta_arriesgada"},
		]
	},
	{
		"titulo": "El Mercader Errante",
		"descripcion": "Una extraña embarcación se acerca. El capitán ofrece cartas raras a precio especial.",
		"opciones": [
			{"texto": "Comprar por 50 🪙  →  carta aleatoria al mazo",       "efecto": "comprar_carta"},
			{"texto": "Declinar  →  nada pasa",                               "efecto": "nada"},
		]
	},
	{
		"titulo": "La Cueva de los Ecos",
		"descripcion": "Una cueva submarina emite pulsos de energía misteriosa. Sientes que podría afectar a tu mazo.",
		"opciones": [
			{"texto": "Explorar  →  elimina la carta más débil del mazo (la de menor valor)", "efecto": "eliminar_debil"},
			{"texto": "Ignorar  →  nada pasa",                                "efecto": "nada"},
		]
	},
]

@onready var lbl_titulo: Label = $CanvasLayer/LblTitulo
@onready var lbl_descripcion: Label = $CanvasLayer/LblDescripcion
@onready var contenedor_opciones: VBoxContainer = $CanvasLayer/ContenedorOpciones
@onready var lbl_resultado: Label = $CanvasLayer/LblResultado
@onready var btn_continuar: Button = $CanvasLayer/BtnContinuar

var evento_actual: Dictionary = {}

func _ready() -> void:
	btn_continuar.visible = false
	btn_continuar.pressed.connect(_salir)
	evento_actual = EVENTOS[randi() % EVENTOS.size()]
	lbl_titulo.text = evento_actual["titulo"]
	lbl_descripcion.text = evento_actual["descripcion"]
	_mostrar_opciones()

func _mostrar_opciones() -> void:
	for child in contenedor_opciones.get_children():
		child.queue_free()
	for opcion in evento_actual["opciones"]:
		var btn = Button.new()
		btn.text = opcion["texto"]
		btn.pressed.connect(func(): _aplicar_efecto(opcion["efecto"]))
		contenedor_opciones.add_child(btn)

func _aplicar_efecto(efecto: String) -> void:
	var resultado: String = ""
	match efecto:
		"nada":
			resultado = "Sigues tu ruta sin novedad."
		"rescatar":
			GameState.vida_capitan = max(1, GameState.vida_capitan - 10)
			GameState.oro += 50
			resultado = "Rescataste al marinero. Te agradece con 50 monedas, pero perdiste 10 HP."
		"tormenta_prudente":
			GameState.vida_capitan = max(1, GameState.vida_capitan - 10)
			GameState.oro += 50
			resultado = "Arriaste velas a tiempo. -10 HP, +50 🪙."
		"tormenta_arriesgada":
			GameState.oro += 20
			if randi() % 2 == 0:
				resultado = "¡Resististe la tormenta! +20 🪙."
			else:
				GameState.vida_capitan = max(1, GameState.vida_capitan - 25)
				resultado = "La tormenta os azotó fuerte. -25 HP, +20 🪙."
		"comprar_carta":
			if GameState.oro >= 50:
				GameState.oro -= 50
				var pool = _cargar_pool()
				if not pool.is_empty():
					var nueva = GameState.duplicar_carta(pool[randi() % pool.size()])
					GameState.mazo_coleccion.append(nueva)
					resultado = "Compraste «" + nueva.nombre + "» por 50 🪙."
				else:
					GameState.oro += 50  # Devolver si no hay cartas
					resultado = "El mercader no tenía cartas para ti."
			else:
				resultado = "No tienes suficiente oro."
		"eliminar_debil":
			var candidatas: Array = []
			for carta in GameState.mazo_coleccion:
				if carta.tipo_carta == CardData.TipoCarta.ATAQUE and carta.valor > 0:
					candidatas.append(carta)
			if candidatas.size() > 1:
				var mas_debil = candidatas[0]
				for c in candidatas:
					if c.valor < mas_debil.valor:
						mas_debil = c
				GameState.mazo_coleccion.erase(mas_debil)
				resultado = "La energía eliminó «" + mas_debil.nombre + "» de tu mazo."
			else:
				resultado = "No hay suficientes ataques en tu mazo. La cueva no actúa."

	lbl_resultado.text = resultado
	btn_continuar.visible = true
	# Deshabilitar todos los botones de opción
	for child in contenedor_opciones.get_children():
		if child is Button:
			child.disabled = true

func _cargar_pool() -> Array[CardData]:
	var cartas: Array[CardData] = []
	var dir = DirAccess.open("res://resources/cards/")
	if dir:
		dir.list_dir_begin()
		var archivo = dir.get_next()
		while archivo != "":
			if archivo.ends_with(".tres"):
				var carta = load("res://resources/cards/" + archivo) as CardData
				if carta:
					cartas.append(carta)
			archivo = dir.get_next()
	return GameState.get_cartas_recompensa_disponible(cartas)

func _salir() -> void:
	GameState.nodo_actual.completado = true
	GameState.guardar_run()
	get_tree().change_scene_to_file("res://scenes/map/MapScene.tscn")
