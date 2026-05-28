extends Node

const CURACION:int=15
const BONUS_MEJORA: float=0.5 

@onready var lbl_info:Label=$CanvasLayer/LblInfo
@onready var contenedor_cartas: HBoxContainer=$CanvasLayer/ContenedorCartas
@onready var btn_curar: Button=$CanvasLayer/BtnCurar
@onready var btn_salir: Button=$CanvasLayer/BtnSalir

var accion_usada: bool=false

func _ready() -> void:
	btn_curar.pressed.connect(_curar)
	btn_salir.pressed.connect(_salir)
	lbl_info.text="Elige UNA accion: MEJORA O CURA"+str(CURACION)
	_mostrar_cartas()

func _mostrar_cartas() ->void:
	for child in contenedor_cartas.get_children():
		child.queue_free()
	for carta in GameState.mazo_coleccion:
		var btn=Button.new()
		btn.custom_minimum_size=Vector2(140,180)
		if carta.better:
			btn.text=carta.nombre+"\n(YA MEJORADA)"
			btn.disabled=true
		else:
			btn.text=carta.nombre +"\n"+str(int(carta.valor*BONUS_MEJORA))+"valor\n(MEJORADA)"
			btn.pressed.connect(func():_mejorar_carta(carta))
		contenedor_cartas.add_child(btn)

func _mejorar_carta(carta:CardData)->void:
	if accion_usada:
		return
	accion_usada=true
	var valor_anterior: int=carta.valor
	carta.better=true
	carta.valor=int(carta.valor*(1.0+BONUS_MEJORA))
	carta.nombre=carta.nombre+ "+"
	carta.descripcion=carta.descripcion.replace(str(valor_anterior),str(carta.valor))
	lbl_info.text="MEJORADA"+carta.nombre+"VETE A DORMIR YA!!!!"
	btn_curar.disabled=true
	_mostrar_cartas()
func _curar()->void:
	if accion_usada:
		return
	accion_usada=true
	GameState.vida_capitan=min(GameState.vida_capitan+CURACION,GameState.vida_maxima_capitan)
	lbl_info.text="TE CURASTE"+str(CURACION)+" VETE A DORMIR YA!!!"
	btn_curar.disabled=true
func _salir()->void:
	GameState.nodo_actual.completado=true
	GameState.guardar_run()
	get_tree().change_scene_to_file("res://Scenes/Map/MapScene.tscn")
