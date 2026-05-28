class_name EnemyUI
extends Node2D

@export var datos: EnemyData

@onready var sprite: Sprite2D = $Sprite
@onready var barra_vida: ProgressBar = $BarraVida
@onready var lbl_vida: Label = $LblVida
@onready var lbl_bloqueo: Label = $LblBloqueo
@onready var lbl_Intencion: Label = $LblIntencion
@onready var icono_intencion: TextureRect = $IconoIntencion
@onready var boton_seleccion: Button = $BotonSeleccion

var hp_actual: int
var bloqueo_actual: int = 0
var fase_actual: int = 1
var intencion_actual: Dictionary = {}
var muerto: bool = false   # ← NUEVO, lo usa CombatManager en MIXTO_FURIA
var estado: StatusEffect = StatusEffect.new()

signal enemigo_muerto
signal fase_cambiada(nueva_fase: int)


func _ready() -> void:
	push_warning("[ENEMY] _ready de " + str(datos.nombre if datos else "DATOS NULL"))
	if datos == null:
		push_error("[ENEMY] datos es null!")
		return
	push_warning("[ENEMY] hp_maximo: " + str(datos.hp_maximo))
	push_warning("[ENEMY] imagen asignada: " + str(datos.imagen))
	push_warning("[ENEMY] patron size: " + str(datos.patron.size()))
	push_warning("[ENEMY] mi posicion: " + str(position))
	push_warning("[ENEMY] sprite existe: " + str(sprite != null))
	
	hp_actual = datos.hp_maximo
	if datos.imagen:
		sprite.texture = datos.imagen
		sprite.scale   = datos.sprite_scale
		sprite.flip_h  = datos.flip_h
		push_warning("[ENEMY] sprite.texture asignada")
	else:
		push_warning("[ENEMY] datos.imagen es NULL")
	barra_vida.max_value = datos.hp_maximo
	actualizar_hud()
	push_warning("[ENEMY] _ready terminado")
	boton_seleccion.mouse_filter = Control.MOUSE_FILTER_STOP
	boton_seleccion.disabled = false
	boton_seleccion.flat = true
	boton_seleccion.z_index = 10
	push_warning("[ENEMY] boton_seleccion config: filter=" + str(boton_seleccion.mouse_filter) + " size=" + str(boton_seleccion.size))
	boton_seleccion.pressed.connect(func(): push_warning("[ENEMY] CLICK detectado en " + datos.nombre))
	boton_seleccion.pressed.connect(func(): push_warning("[ENEMY] CLICK en " + datos.nombre))
	boton_seleccion.mouse_entered.connect(func(): push_warning("[ENEMY] HOVER en " + datos.nombre))

func mostrar_intencion_para_turno(turno: int) -> void:
	var patron_actual = datos.patron if fase_actual == 1 else datos.patron_fase2
	if patron_actual.is_empty():
		return
	var idx = (turno - 1) % patron_actual.size()
	intencion_actual = patron_actual[idx]
	lbl_Intencion.text = intencion_actual.get("nombre", "?")
	var tipo = intencion_actual.get("tipo", "")
	if tipo == "ataque" or tipo == "ataque_penetrante":
		lbl_Intencion.text += "  (" + str(intencion_actual.get("valor", 0)) + " dmg)"


func ejecutar_intencion(combat_manager: CombatManager) -> void:
	if intencion_actual.is_empty():
		return
	match intencion_actual.get("tipo", ""):
		"ataque":
			var golpes = intencion_actual.get("golpes", 1)
			for _i in golpes:
				combat_manager.recibir_damage(intencion_actual.get("valor", 0))
		"defensa":
			bloqueo_actual += intencion_actual.get("valor", 0)
			actualizar_hud()
		"debilitar":
			combat_manager.estados_jugador.weak += intencion_actual.get("valor", 1)
		"ataque_penetrante":
			combat_manager.recibir_damage_sin_bloqueo(intencion_actual.get("valor", 0))
		"defensa_curacion":
			bloqueo_actual += intencion_actual.get("valor", 0)
			hp_actual = min(datos.hp_maximo, hp_actual + intencion_actual.get("curacion", 0))
			actualizar_hud()


func recibir_damage(cantidad: int) -> void:
	var damage_real = estado.calcular_damage_recibido(cantidad)
	var absorcion = min(bloqueo_actual, damage_real)
	bloqueo_actual -= absorcion
	hp_actual -= (damage_real - absorcion)
	hp_actual = max(0, hp_actual)
	_comprobar_transicion_fase()
	# Flash rojo
	var t = create_tween()
	t.tween_property(sprite, "self_modulate", Color.RED, 0.1)
	t.tween_property(sprite, "self_modulate", Color.WHITE, 0.1)
	actualizar_hud()
	if hp_actual <= 0:
		morir()


func morir() -> void:
	muerto = true
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.4)
	await t.finished
	enemigo_muerto.emit()
	queue_free()


func actualizar_hud() -> void:
	barra_vida.value = hp_actual
	lbl_vida.text = str(hp_actual) + "/" + str(datos.hp_maximo)
	lbl_bloqueo.text = "🛡 " + str(bloqueo_actual) if bloqueo_actual > 0 else ""
	# Construir string de efectos
	var efectos = ""
	if estado.vulnerable > 0:
		efectos += " 💥×" + str(estado.vulnerable)
	if estado.poison > 0:
		efectos += " 🟢×" + str(estado.poison)
	if estado.stun:
		efectos += " 💫"
	# Concatenar intención + efectos
	var nombre_intencion = intencion_actual.get("nombre", "?") if not intencion_actual.is_empty() else ""
	lbl_Intencion.text = nombre_intencion + efectos


func _comprobar_transicion_fase() -> void:
	# Solo transicionar si estoy en fase 1, tengo umbral configurado, y mi HP cayó por debajo del umbral
	if fase_actual != 1:
		return
	if datos.hp_umbral_fase2 <= 0:
		return
	if hp_actual > datos.hp_umbral_fase2:
		return
	fase_actual = 2
	bloqueo_actual += datos.bloqueo_transicion_fase2
	estado.reset_combat()
	fase_cambiada.emit(2)
	actualizar_hud()


func avanzar_patron() -> void:
	pass
func animar_daño() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.5, 0.3, 0.3), 0.08)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func animar_muerte() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
