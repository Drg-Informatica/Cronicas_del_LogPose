class_name CombatManager
extends Node

# Estados de combate 
var energia_actual: int = 0
var vida_capitan: int = 80
var bloqueo_capitan: int = 0

var enemigo_actual: EnemyUI = null
var enemigos: Array[EnemyUI] = []
var turno_actual: int = 1
# Tipos de Carta
var poderes_activos: Array[CardData] = []
var primer_ataque_del_turno: bool = true
# Efectos de carta 
var estados_jugador: StatusEffect = StatusEffect.new()

# Referencia de escena 
@onready var mano: HandDisplay = $"CanvasLayer/ContenedorMano"
@onready var lbl_energia: Label = $CanvasLayer/MarginContainer/HUDCombate/LblEnergia
@onready var lbl_vida: Label = $CanvasLayer/MarginContainer/HUDCombate/LblVidaJugador
@onready var lbl_marea: Label = $CanvasLayer/MarginContainer/HUDCombate/LblMarea
@onready var lbl_mazo: Label = $CanvasLayer/MarginContainer/HUDCombate/LblMazo
@onready var btn_fin_turno: Button = $CanvasLayer/BtnFindeTurno
@onready var posicion_enemigo: Node2D = $PosicionEnemigo
@onready var captain_portrait: TextureRect = $CanvasLayer/MarginContainer/HUDCombate/TextureRect

const SCENE_ENEMY = preload("res://Scenes/Enemies/EnemyUI.tscn")
const SEPARACION_VERTICAL := 120.0
signal combate_ganado
signal combate_perdido


func _ready() -> void:
	push_warning("[COMBAT] _ready empieza")   # ← CAMBIO: push_warning aparece SIEMPRE en Debugger
	push_warning("[COMBAT] nodo_actual: " + str(GameState.nodo_actual))
	if GameState.nodo_actual:
		push_warning("[COMBAT] datos_extra: " + str(GameState.nodo_actual.datos_extra))
	push_warning("[COMBAT] mazo_coleccion size: " + str(GameState.mazo_coleccion.size()))
	
	btn_fin_turno.pressed.connect(fin_de_turno)
	mano.card_jugada.connect(on_carta_jugada)
	Deck_Manager.mano_actual.connect(_on_mano_actual)
	Deck_Manager.mazo_actualizado.connect(_on_mazo_actualizado)
	GameState.marea.marea_cambiada.connect(_on_marea_cambiada)
	push_warning("[COMBAT] señales conectadas")
	
	Deck_Manager.iniciar_combate(GameState.mazo_coleccion)
	push_warning("[COMBAT] deck iniciado")
	
	var lista_enemigos = GameState.nodo_actual.datos_extra.get("enemigos", []) as Array
	push_warning("[COMBAT] lista_enemigos size: " + str(lista_enemigos.size()))
	
	if lista_enemigos.is_empty():
		push_error("CombatScene: nodo_actual.datos_extra['enemigos'] está vacío")
		return
	
	iniciar_combate(lista_enemigos)
	push_warning("[COMBAT] iniciar_combate terminó, enemigos: " + str(enemigos.size()))
	
	_actualizar_hud_marea()


func iniciar_combate(lista_datos: Array) -> void:
	turno_actual = 1
	vida_capitan = GameState.vida_capitan
	var capitan: CptnData = GameState.capitan_actual
	if capitan and capitan.portrait:
		captain_portrait.texture  = capitan.portrait
	poderes_activos.clear()
	estados_jugador.reset_combat()
	_procesar_reliquias_incio_combate()
	primer_ataque_del_turno = true
	GameState.marea.estado_actual = MareaSystem.EstadoMarea.CALMA
	GameState.marea.turno_siguiente_cambio = MareaSystem.TURNOS_POR_MAREA
	
	for nakama in GameState.tripulacion:
		nakama.poder_usado = false
	
	for i in lista_datos.size():
		var datos_e = lista_datos[i] as EnemyData
		var e: EnemyUI = SCENE_ENEMY.instantiate()
		e.datos = datos_e
		posicion_enemigo.add_child(e)
		e.position = Vector2(0, i * SEPARACION_VERTICAL)  # relativo al ancla
		e.enemigo_muerto.connect(_on_enemigo_muerto.bind(e))
		e.boton_seleccion.pressed.connect(_seleccionar_objectivo.bind(e))
		e.fase_cambiada.connect(_on_enemigo_fase_cambiada.bind(e))
		enemigos.append(e)
	
	if enemigos.size() > 0:
		_seleccionar_objectivo(enemigos[0])
	
	iniciar_turno_jugador()


func iniciar_turno_jugador() -> void:
	energia_actual = GameState.energia_maxima
	bloqueo_capitan = 0
	primer_ataque_del_turno = true
	estados_jugador.al_actuar()
	_verificar_poder_resiliencia()
	Deck_Manager.robar_cartas(5)
	_procesar_reliquias_incio_turno()
	_verificar_poderes_tripulacion_inicio_turno()
	_verificar_poderes_ciclicos_tripulacion()
	for e in enemigos:
		e.mostrar_intencion_para_turno(turno_actual)
	actualizar_hud()


func _on_enemigo_muerto(enemigo: EnemyUI) -> void:
	enemigos.erase(enemigo)
	if enemigos.is_empty():
		_procesar_reliquias_al_matar()
		GameState.vida_capitan = vida_capitan
		if GameState.nodo_actual.tipo == MapNodeData.TipoNodo.JEFE:
			GameState.llegando_de_jefe = true
		GameState.nodo_actual.completado = true
		GameState.guardar_run()
		get_tree().change_scene_to_file("res://Scenes/UI/RewardScene.tscn")
	else:
		_seleccionar_objectivo(enemigos[0])
	combate_ganado.emit()


func _verificar_poder_resiliencia() -> void:
	if GameState.capitan_actual == null:
		return
	if GameState.capitan_actual.poder_nombre != "Resiliencia":
		return
	bloqueo_capitan += 3
	actualizar_hud()


func _on_mano_actual(nueva_mano: Array) -> void:
	mano.mostrar_mano(nueva_mano)


func _on_mazo_actualizado(restantes: int) -> void:
	lbl_mazo.text = str(restantes) + " Quedan"


func on_carta_jugada(carta_ui: CardUI) -> void:
	var carta = carta_ui.datos
	var coste = calcular_coste_real(carta_ui.datos)
	if energia_actual < coste:
		return
	energia_actual -= coste
	match carta.tipo_carta:
		CardData.TipoCarta.POWER:
			poderes_activos.append(carta)
			Deck_Manager.exiliar_carta(carta)
			_aplicar_efectos_carta(carta)
			mano.eliminar_card(carta_ui)
			return
		_:
			pass
	_aplicar_efectos_carta(carta)
	enemigo_actual.animar_daño()
	await get_tree().create_timer(0.25).timeout  
	if carta.exhaust:
		Deck_Manager.exiliar_carta(carta)
	else:
		Deck_Manager.descartar_carta(carta)
	mano.eliminar_card(carta_ui)   # ← CAMBIO: era 'carta' (CardData), debe ser 'carta_ui' (CardUI)
	actualizar_hud()


func _aplicar_efectos_carta(carta: CardData) -> void:
	match carta.tipo_efecto:
		CardData.TipoEfecto.DAMAGE:
			for _i in carta.ostias:
				var damage_base = carta.valor
				if primer_ataque_del_turno and _tiene_poder("Espiritu de Batalla"):
					damage_base += (damage_base + carta.valor)
				if primer_ataque_del_turno:
					primer_ataque_del_turno = false
				var damage = estados_jugador.calcular_damage_enviado(damage_base)
				enemigo_actual.recibir_damage(damage)
				_verificar_poder_impacto()
		CardData.TipoEfecto.DEFENSE:
			bloqueo_capitan += carta.valor
		CardData.TipoEfecto.HEAL:
			vida_capitan = min(vida_capitan + carta.valor, GameState.vida_maxima_capitan)
		CardData.TipoEfecto.DRAW_CARD:
			var robadas = Deck_Manager.robar_cartas(carta.valor)
			if robadas >= 2:
				_verificar_pder_flujo_marea()
		CardData.TipoEfecto.POISON:
			enemigo_actual.estado.poison += carta.valor
		CardData.TipoEfecto.WEAKNESS:
			enemigo_actual.estado.weak += carta.valor
		CardData.TipoEfecto.VULNERABLE:
			enemigo_actual.estado.vulnerable += carta.valor
		CardData.TipoEfecto.STUN:
			enemigo_actual.estado.stun = true
		CardData.TipoEfecto.STRENGHT:                              # ← AÑADIDO
			estados_jugador.strenght += carta.valor
		CardData.TipoEfecto.GANAR_ENERGIA:                         # ← AÑADIDO (también faltaba)
			energia_actual = min(energia_actual + carta.valor, GameState.energia_maxima)
	actualizar_hud()
	if carta.valor_2 > 0:
		match carta.tipo_efecto_2:
			CardData.TipoEfecto.POISON:
				enemigo_actual.estado.poison += carta.valor_2
			CardData.TipoEfecto.WEAKNESS:
				enemigo_actual.estado.weak += carta.valor_2
			CardData.TipoEfecto.VULNERABLE:
				enemigo_actual.estado.vulnerable += carta.valor_2
			CardData.TipoEfecto.STUN:
				enemigo_actual.estado.stun = true
			CardData.TipoEfecto.DAMAGE:
				var damage_2 = estados_jugador.calcular_damage_enviado(carta.valor_2)
				enemigo_actual.recibir_damage(damage_2)
			CardData.TipoEfecto.DEFENSE:
				bloqueo_capitan += carta.valor_2
				actualizar_hud()
			CardData.TipoEfecto.HEAL:
				vida_capitan = min(vida_capitan + carta.valor_2, GameState.vida_maxima_capitan)
				actualizar_hud()
			CardData.TipoEfecto.DRAW_CARD:
				Deck_Manager.robar_cartas(carta.valor_2)
			CardData.TipoEfecto.GANAR_ENERGIA:
				energia_actual = min(energia_actual + carta.valor_2, GameState.energia_maxima)
				actualizar_hud()
			CardData.TipoEfecto.STRENGHT:
				estados_jugador.strenght += carta.valor_2


func fin_de_turno() -> void:
	push_warning("[TURN] === Fin de turno ===")
	Deck_Manager.descartar_mano_full()
	
	for e in enemigos:
		var damage_poison = e.estado.procesar_poison()
		if damage_poison > 0:
			e.recibir_damage(damage_poison)
	
	push_warning("[TURN] enemigo_actual: " + str(enemigo_actual))
	push_warning("[TURN] enemigo vivo? hp = " + str(enemigo_actual.hp_actual if enemigo_actual else "NULL"))
	push_warning("[TURN] stun antes de puede_actuar: " + str(enemigo_actual.estado.stun))
	push_warning("[TURN] intencion_actual: " + str(enemigo_actual.intencion_actual))
	
	if enemigo_actual.estado.puede_actuar():
		push_warning("[TURN] puede actuar → ejecuta intención")
		enemigo_actual.estado.al_actuar()
		enemigo_actual.ejecutar_intencion(self)
	else:
		push_warning("[TURN] NO puede actuar (stun) → avanzar patrón")
		enemigo_actual.avanzar_patron()
	
	turno_actual += 1
	GameState.marea.actualizar(turno_actual)
	iniciar_turno_jugador()
	push_warning("[TURN] turno " + str(turno_actual) + " iniciado")


func recibir_damage(cantidad: int) -> void:
	cantidad = estados_jugador.calcular_damage_recibido(cantidad)
	var damage_real = max(0, cantidad - bloqueo_capitan)
	bloqueo_capitan = max(0, bloqueo_capitan - cantidad)
	vida_capitan -= damage_real
	vida_capitan = max(0, vida_capitan)
	_verificar_poderes_tripulacion()
	actualizar_hud()
	if vida_capitan <= 0:
		get_tree().change_scene_to_file("res://Scenes/UI/GameOverScene.tscn")   # ← CAMBIO: ruta real, era ""


func actualizar_hud() -> void:
	lbl_energia.text = str(energia_actual) + "/" + str(GameState.energia_maxima)   # ← CAMBIO: era str(enemigo_actual)
	lbl_vida.text = "❤ " + str(vida_capitan) + "  🛡 " + str(bloqueo_capitan)


func _tiene_poder(nombre_poder: String) -> bool:
	for poder in poderes_activos:
		if poder.nombre == nombre_poder:
			return true
	return false


func _verificar_poder_impacto() -> void:
	push_warning("[IMPACTO] verificando, capitán = " + str(GameState.capitan_actual.nombre if GameState.capitan_actual else "NULL"))
	push_warning("[IMPACTO] poder_nombre = " + str(GameState.capitan_actual.poder_nombre if GameState.capitan_actual else "NULL"))
	if GameState.capitan_actual == null:
		return
	if GameState.capitan_actual.poder_nombre != "Impacto":
		push_warning("[IMPACTO] no es Impacto, saliendo")
		return
	if enemigo_actual == null:
		return
	var roll = randf()
	push_warning("[IMPACTO] tirada: " + str(roll))
	if roll < 0.30:
		push_warning("[IMPACTO] ¡ATURDIDO!")
		enemigo_actual.estado.stun = true
		lbl_energia.text = "⚡IMPACTO!"


func _verificar_poderes_tripulacion() -> void:
	for miembro in GameState.tripulacion:
		match miembro.poder_nombre:
			"Pulso Restaurador":
				if not miembro.poder_usado:
					var umbral = int(GameState.vida_maxima_capitan * 0.40)
					if vida_capitan <= umbral:
						vida_capitan += 12
						vida_capitan = min(vida_capitan, GameState.vida_maxima_capitan)
						miembro.poder_usado = true
						actualizar_hud()


func _verificar_poderes_tripulacion_inicio_turno() -> void:
	for miembro in GameState.tripulacion:
		match miembro.poder_nombre:
			"Lectura Del Viento":
				if GameState.marea.estado_actual != MareaSystem.EstadoMarea.CALMA:
					Deck_Manager.robar_cartas(1)


func calcular_coste_real(carta: CardData) -> int:
	return GameState.marea.calcular_coste(carta)


func _seleccionar_objectivo(enemigo: EnemyUI) -> void:
	push_warning("[SELECT] === Intentando seleccionar: " + enemigo.datos.nombre + " ===")
	push_warning("[SELECT] enemigo_actual ANTES: " + (enemigo_actual.datos.nombre if enemigo_actual else "NULL"))
	push_warning("[SELECT] Total enemigos vivos: " + str(enemigos.size()))
	for e in enemigos:
		push_warning("[SELECT]   - " + e.datos.nombre 
			+ " | boton_disabled=" + str(e.boton_seleccion.disabled)
			+ " | boton_visible=" + str(e.boton_seleccion.visible)
			+ " | boton_modulate_a=" + str(e.boton_seleccion.modulate.a)
			+ " | enemigo_modulate=" + str(e.modulate))
	
	enemigo_actual = enemigo
	for e in enemigos:
		e.modulate = Color(1, 1, 1)
	enemigo.modulate = Color(1.3, 1.3, 0.7)
	push_warning("[SELECT] enemigo_actual DESPUÉS: " + enemigo_actual.datos.nombre)


func _on_enemigo_fase_cambiada(nueva_fase: int, enemigo: EnemyUI) -> void:
	print(enemigo.datos.nombre + " entra en Fase " + str(nueva_fase) + "!")


# Daño que atraviesa el Bloqueo del jugador (Furia del Rey, Fase 2 del jefe).
func recibir_damage_sin_bloqueo(damage: int) -> void:
	vida_capitan -= damage
	vida_capitan = max(0, vida_capitan)
	_verificar_poderes_tripulacion()
	actualizar_hud()
	if vida_capitan <= 0:
		get_tree().change_scene_to_file("res://Scenes/UI/GameOverScene.tscn")


func _on_marea_cambiada(_nuevo_estado) -> void:
	push_warning("[MAREA] cambió a: " + str(_nuevo_estado))
	push_warning("[MAREA] cartas en mano: " + str(mano.cartas_en_mano.size()))
	_actualizar_hud_marea()
	for carta_ui in mano.cartas_en_mano:
		var nuevo_coste = calcular_coste_real(carta_ui.datos)
		push_warning("[MAREA] carta " + carta_ui.datos.nombre + " → coste " + str(nuevo_coste))
		carta_ui.actualizar_coste_visual(nuevo_coste)


func _actualizar_hud_marea() -> void:
	lbl_marea.text = "⚓ Marea: " + GameState.marea.get_nombre_estado()
	lbl_marea.tooltip_text = GameState.marea.get_descripcion_estado()


func _verificar_pder_flujo_marea() -> void:
	if GameState.capitan_actual == null:
		return
	if GameState.capitan_actual.poder_nombre != "Flujo de Marea":
		return
	energia_actual = min(energia_actual + 1, GameState.energia_maxima)
	actualizar_hud()


func _procesar_reliquias_incio_combate() -> void:
	for r in GameState.reliquias:
		match r.nombre:
			"Amuleto de Coral":
				bloqueo_capitan += r.valor


func _procesar_reliquias_incio_turno() -> void:
	for r in GameState.reliquias:
		match r.nombre:
			"Espuela de Capitan":
				if Deck_Manager.mano.size() >= 3:
					estados_jugador.strenght += r.valor


func _procesar_reliquias_al_matar() -> void:
	for r in GameState.reliquias:
		pass


# Cada tripulante con poder_ciclico_tipo != NINGUNO actúa si turno_actual es múltiplo de su N.
func _verificar_poderes_ciclicos_tripulacion() -> void:
	for miembro in GameState.tripulacion:
		if miembro.poder_ciclico_tipo == CrewMemberData.TipoPoderCiclico.NINGUNO:
			continue
		var cada_n = max(1, miembro.poder_ciclico_cada_n_turnos)
		if turno_actual % cada_n != 0:
			continue
		match miembro.poder_ciclico_tipo:
			CrewMemberData.TipoPoderCiclico.DAMAGE:
				var damage = miembro.poder_ciclico_valor
				var cartas_a_robar = max(1, miembro.poder_ciclico_valor_extra)
				if bloqueo_capitan >= damage:
					bloqueo_capitan -= damage
				else:
					var resto = damage - bloqueo_capitan
					bloqueo_capitan = 0
					vida_capitan -= resto
				Deck_Manager.robar_cartas(cartas_a_robar)
				actualizar_hud()
				_mostrar_feedback_poder(miembro, "🩸")
				if vida_capitan <= 0:
					vida_capitan = 0
					combate_perdido.emit()
					return
			CrewMemberData.TipoPoderCiclico.DRAW:
				Deck_Manager.robar_cartas(miembro.poder_ciclico_valor)
				_mostrar_feedback_poder(miembro, "🃏")
			CrewMemberData.TipoPoderCiclico.HEAL:
				vida_capitan = min(vida_capitan + miembro.poder_ciclico_valor,
								   GameState.vida_maxima_capitan)
				actualizar_hud()
				_mostrar_feedback_poder(miembro, "💚")
			CrewMemberData.TipoPoderCiclico.DEFENSE:
				bloqueo_capitan += miembro.poder_ciclico_valor
				actualizar_hud()
				_mostrar_feedback_poder(miembro, "🛡")
			CrewMemberData.TipoPoderCiclico.MIXTO_FURIA:
				for e in enemigos:
					if e != null and not e.muerto:
						e.recibir_damage(miembro.poder_ciclico_valor)   # ← CAMBIO: era recibir_danio
				Deck_Manager.robar_cartas(1)
				_mostrar_feedback_poder(miembro, "🔥")


# Mensaje temporal en el HUD reutilizando LblFeedbackPoder (Cap. 8.3).
func _mostrar_feedback_poder(miembro: CrewMemberData, icono: String) -> void:
	var texto = icono + " " + miembro.nombre + ": " + miembro.poder_ciclico_nombre
	if has_node("../CanvasLayer/HUDCombate/LblFeedbackPoder"):
		$"../CanvasLayer/HUDCombate/LblFeedbackPoder".text = texto
		await get_tree().create_timer(0.9).timeout
		$"../CanvasLayer/HUDCombate/LblFeedbackPoder".text = ""
