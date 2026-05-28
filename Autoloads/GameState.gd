extends Node

var vida_capitan=80
var vida_maxima_capitan:int=80
var oro:int=0
var mazo_coleccion:Array[CardData]
var tripulacion: Array=[]
var reliquias: Array=[]
var nodo_actual:MapNodeData=null
var todos_los_nodos_mapa:Array=[]
#capitan elegido
var capitan_actual:CptnData=null
var energia_maxima: int=3
#MArea
var marea:MareaSystem=MareaSystem.new()
var llegando_de_jefe: bool=false
var fondo_combate_actual: String = ""
var bioma_actual: int = 1
const MAX_TRIPULANTES: int=4
const RUTA_GUARDADO_RUN:String="user://run_state.json"
const RUTA_META:String="user://meta_progress.json"

func _ready() -> void:
	marea.marea_cambiada.connect(_on_marea_cambiada)

func _on_marea_cambiada(_nuevo_estado:MareaSystem.EstadoMarea)->void:
	print("LA MAREA CAMBIA A "+marea.get_nombre_estado())

#CUANDO SELECIONA CAPITAN
func iniciar_nueva_run()->void:
	if capitan_actual !=null:
		vida_capitan=capitan_actual.hp_maximo
		vida_maxima_capitan=capitan_actual.hp_maximo
		energia_maxima=capitan_actual.energia_por_turno
		mazo_coleccion=capitan_actual.crear_mazo_inicial()
	oro=50
	nodo_actual=null
	tripulacion.clear()
	reliquias.clear()
	marea.estado_actual=MareaSystem.EstadoMarea.CALMA
	marea.turno_siguiente_cambio=MareaSystem.TURNOS_POR_MAREA

func guardar_run()->void:
	var data ={
		"vida_capitan":vida_capitan,
		"vida_maxima_capitan":vida_maxima_capitan,
		"energia_maxima":energia_maxima,
		"oro":oro,
		"capitan_actual":capitan_actual.resource_path if capitan_actual else null,
		"mazo":mazo_coleccion.map(func(c):return c.ruta_origen),
		"tripulacion":tripulacion.map(func(t):return t.resource_path),
		"reliquias":reliquias.map(func(r):return r.resource_path),
		"mapa":_serializar_mapa(),
		"nodo_actual_idx": todos_los_nodos_mapa.find(nodo_actual)if nodo_actual else -1
	}
	var archivo =FileAccess.open(RUTA_GUARDADO_RUN,FileAccess.WRITE)
	if archivo==null:
		push_error("NO SE PUEDO GUARDAR RUN:"+str(FileAccess.get_open_error()))
		return
	archivo.store_string(JSON.stringify(data,"\t"))
	archivo.close()
func cargar_run()->bool:
	if not FileAccess.file_exists(RUTA_GUARDADO_RUN):
		return false
	var archivo = FileAccess.open(RUTA_GUARDADO_RUN,FileAccess.READ)
	if archivo==null:
		return false
	var texto=archivo.get_as_text()
	archivo.close()
	var data = JSON.parse_string(texto)
	if not (data is Dictionary):
		return false
	vida_capitan=int(data.get("vida_capitan",80))
	vida_maxima_capitan=int(data.get("vida_maxima_capitan",80))
	energia_maxima=int(data.get("energia_maxima",3))
	oro=int(data.get("oro",0))
	mazo_coleccion.clear()
	for ruta in data.get("mazo",[]):
		var carta = load(ruta) as CardData
		if carta:
			var copia=carta.duplicate()
			copia.ruta_origen=ruta
			mazo_coleccion.append(copia)
	tripulacion.clear()
	for ruta in data.get("tripulacion",[]):
		var miembro = load(ruta) as CrewMemberData
		if miembro:
			tripulacion.append(miembro)
	reliquias.clear()
	for ruta in data.get("reliquias",[]):
		var miembro = load(ruta) as RelicData
		if miembro:
			reliquias.append(miembro)
	var ruta_capitan=data.get("capitan_actual",null)
	if ruta_capitan:
		capitan_actual=load(ruta_capitan)as CptnData
	var mapa_data:Array=data.get("mapa",[])
	if not mapa_data.is_empty():
		_deserializar_mapa(mapa_data)
		var idx: int = int (data.get("nodo_actual_idx",-1))
		if idx>=0 and idx<todos_los_nodos_mapa.size():
			nodo_actual=todos_los_nodos_mapa[idx]
		else:
			nodo_actual=null
	else:
		todos_los_nodos_mapa.clear()
		nodo_actual=null
	return true

func eliminar_guardado_run()->void:
	if FileAccess.file_exists(RUTA_GUARDADO_RUN):
		var dir:=DirAccess.open("user://")
		if dir:
			dir.remove("run_state.json")
func duplicar_carta(carta:CardData)->CardData:
	var copia:CardData=carta.duplicate()
	copia.ruta_origen+carta.ruta_origen if carta.ruta_origen !="" else carta.resource_path
	return copia
#PROGRTRESION META 
func guardar_meta (cartas_desbloqueadas:Array,capitanes_desbloqueados:Array)->void:
	var data={
		"cartas":cartas_desbloqueadas,
		"capitanes":capitanes_desbloqueados,
	}
	var archivo = FileAccess.open(RUTA_META,FileAccess.WRITE)
	if archivo==null:
		push_error("NO SE PUDO GUARDAR META:"+str(FileAccess.get_open_error()))
		return
	archivo.store_string(JSON.stringify(data,"\t"))
	archivo.close()

func cargar_meta()->Dictionary:
	var vacio: Dictionary={"cartas":[],"capitanes":[]}
	if not FileAccess.file_exists(RUTA_META):
		return vacio
	var archivo = FileAccess.open(RUTA_META,FileAccess.READ)
	if archivo==null:
		return vacio
	var texto =  archivo.get_as_text()
	archivo.close()
	var data = JSON.parse_string(texto)
	if not (data as Dictionary):
		return vacio
	var resultado: Dictionary={
		"cartas": data.get("cartas",[])if data.get("cartas",[])is Array else[],
		"capitanes": data.get("capitanes",[])if data.get("capitanes",[])is Array else[],
	}
	return resultado
func _calcular_nuevas_cartas_desbloqueadas()->Array:
	#CONDICIONES DE DESBLOQUEO
	var rutas: Array=[]
	for carta in mazo_coleccion:
		var ruta = carta.ruta_origen if carta.ruta_origen !=""else carta.resource_path
		if ruta !="" and ruta not in rutas:
			rutas.append(ruta)
	return rutas
func on_ruta_completada(victoria:bool)->void:
	var meta = cargar_meta()
	if victoria:
		var nuevas_cartas=_calcular_nuevas_cartas_desbloqueadas()
		for carta in nuevas_cartas:
			if carta not in meta.cartas:
				meta.cartas.append(carta)
	eliminar_guardado_run()
	guardar_meta(meta.cartas,meta.capitanes)
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")#MAINSCENE
#RELQUIAS y CRew + rewards 
func aplicar_reliquias_inicio_bioma()->void:
	for r in reliquias:
		if r.trigger == RelicData.TriggerTipo.PASIVA:
			match r.nombre:
				"Fragmento de Poneglyph":
					vida_maxima_capitan+=r.valor
func reclutar_nakama(nakama: CrewMemberData) -> bool:
	if tripulacion.size() >= MAX_TRIPULANTES:
		print("¡La tripulación está completa!")
		return false
	tripulacion.append(nakama)

	# --- Regalo al reclutar (Cap. 8.3 bis) ---
	for ruta in nakama.cartas_regalo:
		var carta = load(ruta) as CardData
		if carta == null:
			push_warning("Carta regalo no encontrada: " + ruta)
			continue
		var copia = duplicar_carta(carta)   # helper del Cap. 10 que preserva ruta_origen
		Deck_Manager.mazo.append(copia)
		print("  + Carta regalo añadida: " + copia.nombre)
	return true
func tiene_esencia_disponible(esencia:CardData.Esencia)->bool:
	if esencia==CardData.Esencia.FURIA or esencia==CardData.Esencia.COLOSO:
		return true
	for nakama in tripulacion: 
		if nakama.esencia_aportada==esencia:
			return true
	return false 

func get_cartas_recompensa_disponible(pool_completo:Array[CardData])->Array[CardData]:
	var disponibles: Array[CardData]=[]
	for carta in pool_completo:
		if carta.esencia==CardData.Esencia.DOMINACION:
			var tiene_forjado = false
			for t in tripulacion:
				if t.rol==CrewMemberData.Rol.NONAME:
					tiene_forjado=true
					break
			if not tiene_forjado:
				continue
		if tiene_esencia_disponible(carta.esencia):
			disponibles.append(carta)
	return disponibles
func ganar_reliquia(reliquia: RelicData) -> void:
	reliquias.append(reliquia)
	if reliquia.trigger == RelicData.TriggerTipo.PASIVA:
		match reliquia.nombre:
			"Fragmento de Poneglyph":
				vida_maxima_capitan += reliquia.valor
				vida_capitan = min(vida_capitan + reliquia.valor, vida_maxima_capitan)

#SERIALIZACION de DATOS
func _serializar_enemy_data(e:EnemyData)->Dictionary:
	return{
		"nombre":e.nombre,
		"hp_maximo":e.hp_maximo,
		"bloqueo_base":e.bloqueo_base,
		"patron":e.patron,
		"hp_umbral_fase2":e.hp_umbral_fase2,
		"patron_fase2":e.patron_fase2,
		"":e.bloqueo_transicion_fase2,
	}
func _deserializar_enemy_data(d:Dictionary)->EnemyData:
	var e:=EnemyData.new()
	e.nombre = d.get("nombre","")
	e.hp_maximo=d.get("hp_maximo",50)
	e.bloqueo_base=d.get("bloqueo_base",0)
	e.patron=d.get("patron",[])
	e.hp_umbral_fase2=d.get("hp_umbral_fase2",0)
	e.patron_fase2=d.get("patron_fase2",[])
	e.bloqueo_transicion_fase2=d.get("bloqueo_transicion_fase2",0)
	return e
func _serializar_datos_extra(de:Dictionary)->Dictionary:
	var resultado:Dictionary={}
	for clave in de:
		if clave =="enemigos"and de[clave]is Array:
			var lista:Array=[]
			for e in de[clave]:
				if e is EnemyData:
					lista.append(_serializar_enemy_data(e))
			resultado["enemigos_data"]=lista
		else:
			resultado[clave]=de[clave]
	return resultado
func _to_int_array(arr:Array)->Array:
	var resultado:Array=[]
	for v in arr:
		if v is float or v is int:
			resultado.append(int(v))
		else:
			resultado.append(v)
	return resultado
func _deserializar_datos_extra(de:Dictionary)->Dictionary:
	var resultado: Dictionary=de.duplicate()
	if de.has("enemigos_data"):
		var lista: Array=[]
		for d in de["enemigos_data"]:
			lista.append(_deserializar_enemy_data(d))
		resultado["enemigos"]=lista
		resultado.erase("enemigos_data")
	return resultado
func _serializar_mapa()->Array:
	var mapa_data:Array=[]
	for nodo in todos_los_nodos_mapa:
		mapa_data.append({
			"tipo":nodo.tipo,
			"bioma":nodo.bioma,
			"posicion_x":nodo.posicion.x,
			"posicion_y":nodo.posicion.y,
			"completado":nodo.completado,
			"nodos_siguientes":[],
		})
	for i in todos_los_nodos_mapa.size():
		for siguiente in todos_los_nodos_mapa[i].nodos_siguientes:
			var idx: int=todos_los_nodos_mapa.find(siguiente)
			if idx >=0:
				mapa_data[i]["nodos_siguientes"].append(idx)
	return mapa_data
func _deserializar_mapa(mapa_data:Array)->void:
	todos_los_nodos_mapa.clear()
	for nodo_dict in mapa_data:
		var nodo:=MapNodeData.new(
			int(nodo_dict.get("tipo",MapNodeData.TipoNodo.COMBATE)) as MapNodeData.TipoNodo,
			int(nodo_dict.get("bioma",1)),
			Vector2(nodo_dict.get("posicion_x",0.0),nodo_dict.get("posicion_y",0.0))
		)
		nodo.completado=nodo_dict.get("completado",false)
		nodo.datos_extra=_deserializar_datos_extra(nodo_dict.get("datos_extra",{}))
		todos_los_nodos_mapa.append(nodo)
	for i in mapa_data.size():
		for idx_siguiente in mapa_data[i].get("nodos_siguientes",[]):
			var idx:int=int(idx_siguiente)
			if idx >=0 and idx<todos_los_nodos_mapa.size():
				todos_los_nodos_mapa[i].nodos_siguientes.append(todos_los_nodos_mapa[idx])
