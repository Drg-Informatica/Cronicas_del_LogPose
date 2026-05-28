class_name HandDisplay
extends HBoxContainer

const SCENE_CARD = preload("res://Scenes/Card/card_ui.tscn")

var cartas_en_mano: Array[CardUI] = []   # ← renombrada para coincidir con CombatManager

signal card_jugada(card_ui: CardUI)


func mostrar_mano(lista_datos: Array[CardData]) -> void:
	# Limpiar mano anterior
	for card in cartas_en_mano:
		card.queue_free()
	cartas_en_mano.clear()
	
	# Crear una CardUI por cada CardData
	for datos in lista_datos:
		var card_ui = SCENE_CARD.instantiate() as CardUI
		if card_ui == null:
			push_error("HandDisplay: SCENE_CARD.instantiate() devolvió null")
			continue
		add_child(card_ui)            # ← añadir al árbol PRIMERO
		card_ui.datos = datos          # ← luego asignar datos
		cartas_en_mano.append(card_ui)
		card_ui.carta_soltada.connect(_on_carta_soltada)


func eliminar_card(card_ui: CardUI) -> void:
	cartas_en_mano.erase(card_ui)
	card_ui.queue_free()


func _on_carta_soltada(card_ui: CardUI, posiciones: Vector2) -> void:
	var zona_juego = get_tree().current_scene.get_node_or_null("CanvasLayer/ZonaJuego")
	if zona_juego == null:
		push_warning("HandDisplay: no encuentro CanvasLayer/ZonaJuego en la escena actual")
		return
	if zona_juego.get_global_rect().has_point(posiciones):
		card_jugada.emit(card_ui)
