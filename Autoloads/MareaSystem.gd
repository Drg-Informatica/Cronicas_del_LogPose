class_name MareaSystem
extends RefCounted

enum EstadoMarea {
	CALMA,        # sin modificador
	TORMENTA,     # Cartas Coloso +1, Cartas Deriva -1
	NIEBLA,       # Cartas Furia +1, Cartas Deriva -1
	CORRIENTE,    # Cartas Deriva -1
	LUZ_LUNAR,    # Cartas Furia y Coloso -1
}

const TURNOS_POR_MAREA: int = 3

var estado_actual: EstadoMarea = EstadoMarea.CALMA
var turno_siguiente_cambio: int = TURNOS_POR_MAREA

signal marea_cambiada(nuevo_estado: EstadoMarea)


func actualizar(turno_actual: int) -> void:
	if turno_actual >= turno_siguiente_cambio:
		_cambiar_marea()
		turno_siguiente_cambio = turno_actual + TURNOS_POR_MAREA


func _cambiar_marea() -> void:
	var estados_posibles = [
		EstadoMarea.CALMA,
		EstadoMarea.TORMENTA,
		EstadoMarea.NIEBLA,
		EstadoMarea.CORRIENTE,
		EstadoMarea.LUZ_LUNAR,
	]
	estados_posibles.erase(estado_actual)
	estado_actual = estados_posibles[randi() % estados_posibles.size()]
	marea_cambiada.emit(estado_actual)


func calcular_coste(datos: CardData) -> int:
	var coste = datos.coste_energia
	match estado_actual:
		EstadoMarea.TORMENTA:
			if datos.esencia == CardData.Esencia.COLOSO:
				coste += 1
			elif datos.esencia == CardData.Esencia.DERIVA:
				coste = max(0, coste - 1)
		EstadoMarea.NIEBLA:
			if datos.esencia == CardData.Esencia.FURIA:
				coste += 1
			elif datos.esencia == CardData.Esencia.DERIVA:
				coste = max(0, coste - 1)
		EstadoMarea.CORRIENTE:
			if datos.esencia == CardData.Esencia.DERIVA:
				coste = max(0, coste - 1)
		EstadoMarea.LUZ_LUNAR:
			if datos.esencia == CardData.Esencia.FURIA:
				coste = max(0, coste - 1)
			elif datos.esencia == CardData.Esencia.COLOSO:
				coste = max(0, coste - 1)
	return coste


func get_nombre_estado() -> String:
	return EstadoMarea.keys()[estado_actual]


func get_descripcion_estado() -> String:
	match estado_actual:
		EstadoMarea.CALMA: return "El mar está en Calma"
		EstadoMarea.TORMENTA: return "El mar está en Tormenta, CÚBRETE"
		EstadoMarea.NIEBLA: return "El mar tiene Niebla, NO VEO BIEN"
		EstadoMarea.CORRIENTE: return "El mar fluye, navegante"
		EstadoMarea.LUZ_LUNAR: return "La Diosa te ha ELEGIDO"
	return ""
