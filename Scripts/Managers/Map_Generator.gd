class_name MapGenerator
extends RefCounted

const NODOS_POR_CAPA: int = 3
const CAPAS_POR_BIOMA: int = 5
const SEPARACION_X: float = 200.0
const SEPARACION_Y: float = 150.0

const DISTRIBUCION_DE_CAPAS = [
	[MapNodeData.TipoNodo.COMBATE, MapNodeData.TipoNodo.COMBATE, MapNodeData.TipoNodo.COMBATE],
	[MapNodeData.TipoNodo.COMBATE, MapNodeData.TipoNodo.TIENDA, MapNodeData.TipoNodo.EVENTO],
	[MapNodeData.TipoNodo.ELITE, MapNodeData.TipoNodo.EVENTO, MapNodeData.TipoNodo.EVENTO],
	[MapNodeData.TipoNodo.NOCHE_CABINA, MapNodeData.TipoNodo.COMBATE, MapNodeData.TipoNodo.ELITE],
	[MapNodeData.TipoNodo.JEFE],
]

func generar(bioma_actual: int = 1) -> Array:
	var todos_los_nodos: Array = []
	var capa_anterior: Array = []
	
	for capa in range(CAPAS_POR_BIOMA):
		var tipos = DISTRIBUCION_DE_CAPAS[capa].duplicate()
		tipos.shuffle()
		var nodo_por_capa = tipos.size()
		var capa_actual: Array = []
		
		for i in nodo_por_capa:
			var x_offset = (i - (nodo_por_capa - 1) / 2.0) * SEPARACION_X
			var pos = Vector2(x_offset, -capa * SEPARACION_Y)
			var nodo = MapNodeData.new(tipos[i], bioma_actual, pos)
			_rellenar_datos_extra(nodo)
			capa_actual.append(nodo)
			todos_los_nodos.append(nodo)
		
		if not capa_anterior.is_empty():
			_conectar_capas(capa_anterior, capa_actual)
		capa_anterior = capa_actual
	
	return todos_los_nodos


func _conectar_capas(anterior: Array, actual: Array) -> void:
	for nodo_a in anterior:
		var conexiones = randi_range(1, 2)
		var destinos = actual.duplicate()
		destinos.shuffle()
		for i in min(conexiones, destinos.size()):
			if destinos[i] not in nodo_a.nodos_siguientes:
				nodo_a.nodos_siguientes.append(destinos[i])
	
	for nodo_b in actual:
		var tiene_entrante = false
		for nodo_a in anterior:
			if nodo_b in nodo_a.nodos_siguientes:
				tiene_entrante = true
				break
		if not tiene_entrante:
			var origen = anterior[randi() % anterior.size()]
			origen.nodos_siguientes.append(nodo_b)


func _rellenar_datos_extra(nodo: MapNodeData) -> void:
	push_warning("[MAPGEN] rellenando tipo: " + str(nodo.tipo))
	match nodo.tipo:
		MapNodeData.TipoNodo.COMBATE:
			if randf() < 0.30:
				nodo.datos_extra["enemigos"] = [
					EnemyData.crear_marinero_de_abordaje(),
					EnemyData.crear_marinero_de_abordaje()
				]
				nodo.datos_extra["recompensa"] = {"oro": 30}
			else:
				nodo.datos_extra["enemigos"] = [EnemyData.crear_grumete_rabioso()]
				nodo.datos_extra["recompensa"] = {"oro": 25}
		MapNodeData.TipoNodo.ELITE:
			push_warning("[MAPGEN] creando élite...")
			var lugarteniente = EnemyData.crear_lugarteniente()
			push_warning("[MAPGEN] lugarteniente: " + str(lugarteniente))
			nodo.datos_extra["enemigos"] = [lugarteniente]
			nodo.datos_extra["recompensa"] = {"oro": 45}
		MapNodeData.TipoNodo.JEFE:
			push_warning("[MAPGEN] creando jefe...")
			var corsario = EnemyData.crear_corsario_de_la_corona()
			push_warning("[MAPGEN] corsario: " + str(corsario))
			nodo.datos_extra["enemigos"] = [corsario]
			nodo.datos_extra["recompensa"] = {"oro": 80}
		# resto igual
		MapNodeData.TipoNodo.TIENDA:
			nodo.datos_extra["oro_disponible"] = randi_range(80, 120)
		
		MapNodeData.TipoNodo.NOCHE_CABINA:
			# La cabina restaura vida y opcionalmente mejora una carta
			nodo.datos_extra["curacion_porcentaje"] = 0.30   # cura 30% de vida máxima
			nodo.datos_extra["puede_mejorar_carta"] = true
		
		MapNodeData.TipoNodo.EVENTO:
			# El evento se elige aleatoriamente al entrar
			var eventos_disponibles: Array[String] = [
				"naufrago",
				"tesoro_misterioso",
				"sirena",
				"barco_fantasma",
			]
			nodo.datos_extra["evento_id"] = eventos_disponibles[randi() % eventos_disponibles.size()]
