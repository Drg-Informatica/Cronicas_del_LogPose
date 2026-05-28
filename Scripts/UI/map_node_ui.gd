class_name MapNodeUI
extends Node2D

const ICONOS_NODO: Dictionary = {
	MapNodeData.TipoNodo.COMBATE:      preload("res://Assets/Sprites/Relics/icon_combat.tres"),
	MapNodeData.TipoNodo.ELITE:        preload("res://Assets/Sprites/Relics/icon_combat.tres"),
	MapNodeData.TipoNodo.TIENDA:       preload("res://Assets/Sprites/Relics/icon_shop.tres"),
	MapNodeData.TipoNodo.EVENTO:       preload("res://Assets/Sprites/Relics/icon_event.tres"),
	MapNodeData.TipoNodo.NOCHE_CABINA: preload("res://Assets/Sprites/Relics/icon_noche.tres"),
	MapNodeData.TipoNodo.JEFE:         preload("res://Assets/Sprites/Relics/icon_boss.tres"),
}

const COLOR_NODO: Dictionary = {
	MapNodeData.TipoNodo.COMBATE:      Color("#e63946"),
	MapNodeData.TipoNodo.ELITE:        Color("#c1121f"),
	MapNodeData.TipoNodo.TIENDA:       Color("#f4a261"),
	MapNodeData.TipoNodo.EVENTO:       Color("#457b9d"),
	MapNodeData.TipoNodo.NOCHE_CABINA: Color("#2a9d8f"),
	MapNodeData.TipoNodo.JEFE:         Color("#9b2226"),
}

@onready var icon_rect: TextureRect = $Icon
@onready var boton: Button          = $Boton
@onready var background: Sprite2D   = $Background 

var datos: MapNodeData
var accesible: bool = false

signal nodo_pulsado(datos: MapNodeData)


func _ready() -> void:
	if datos == null:
		push_error("[MapNodeUI] datos es null")
		return
	
	var icono: Texture2D = ICONOS_NODO.get(datos.tipo, null)
	if icono:
		icon_rect.texture = icono
	
	# Color del fondo según el tipo
	if background:
		background.modulate = COLOR_NODO.get(datos.tipo, Color.WHITE)
	
	# El icono lo dejamos blanco para que se vea sobre el fondo de color
	icon_rect.modulate = Color.WHITE
	
	boton.flat = true
	boton.modulate.a = 0.0
	boton.pressed.connect(_on_boton_pressed)
	refrescar_visual()


func _on_boton_pressed() -> void:
	if datos.completado or not accesible:
		return
	nodo_pulsado.emit(datos)


func set_accesible(valor: bool) -> void:
	accesible = valor
	refrescar_visual()


func refrescar_visual() -> void:
	if datos.completado:
		modulate = Color(0.45, 0.45, 0.45)
		boton.disabled = true
	elif accesible:
		modulate = Color.WHITE
		boton.disabled = false
	else:
		modulate = Color(0.3, 0.3, 0.3, 0.7)
		boton.disabled = true
