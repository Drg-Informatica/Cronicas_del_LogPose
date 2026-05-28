class_name CaptainSelectionScene
extends Node

@onready var hbox_capitanes: HBoxContainer = $CanvasLayer/MarginContainer/VBox/HBoxCapitanes
@onready var full_art_rect: TextureRect = $CanvasLayer/MarginContainer/VBox/FullArtContainer/FullArt
@onready var name_label: Label          = $CanvasLayer/MarginContainer/VBox/InfoPanel/NameLabel
@onready var accent_bg: ColorRect       = $AccentBackground

func _ready() -> void:
	var capitanes = _cargar_capitanes()
	for capitan in capitanes:
		_crear_tarjeta_capitan(capitan)

func _mostrar_capitan(capitan: CptnData) -> void:
	name_label.text = capitan.nombre
	if capitan.full_art:
		full_art_rect.texture = capitan.full_art
	accent_bg.color = Color(
		capitan.color_acento.r,
		capitan.color_acento.g,
		capitan.color_acento.b,
		0.25
	)

func _crear_tarjeta_capitan(capitan: CptnData) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 220)
	var vbox := VBoxContainer.new()
	
	# --- Retrato ---
	var retrato := TextureRect.new()
	retrato.texture = capitan.portrait   # usa portrait (miniatura), no full_art
	retrato.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retrato.custom_minimum_size = Vector2(0, 80)   # altura fija, ancho flexible
	
	# --- Textos ---
	var lbl_nombre := Label.new()
	lbl_nombre.text = capitan.nombre
	
	var lbl_stats := Label.new()
	lbl_stats.text = "❤ %d HP   |   %d⚡/turno" % [capitan.hp_maximo, capitan.energia_por_turno]
	
	var lbl_poder := Label.new()
	lbl_poder.text = "⚡ " + capitan.poder_nombre + ": " + capitan.poder_descripcion
	lbl_poder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var lbl_mazo := Label.new()
	lbl_mazo.text = "Mazo: " + str(capitan.rutas_mazo_inicial.size()) + " cartas"
	
	var btn := Button.new()
	btn.text = "Seleccionar"
	
	# --- Montaje ---
	vbox.add_child(retrato)
	vbox.add_child(lbl_nombre)
	vbox.add_child(lbl_stats)
	vbox.add_child(lbl_poder)
	vbox.add_child(lbl_mazo)
	vbox.add_child(btn)
	panel.add_child(vbox)
	hbox_capitanes.add_child(panel)
	
	btn.pressed.connect(func(): _elegir_capitan(capitan))
	panel.mouse_entered.connect(func(): _mostrar_capitan(capitan))

func _elegir_capitan(capitan: CptnData) -> void:
	GameState.capitan_actual = capitan
	GameState.iniciar_nueva_run()  # Usa los datos del capitán para inicializar el run
	get_tree().change_scene_to_file("res://scenes/map/MapScene.tscn")

func _cargar_capitanes() -> Array[CptnData]:
	var capitanes: Array[CptnData] = []
	capitanes.append(CptnData.crear_kael_el_errante())
	capitanes.append(CptnData.crear_petra_la_colosa())
	capitanes.append(CptnData.crear_lyra_de_la_deriva())
	return capitanes
