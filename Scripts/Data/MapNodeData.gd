class_name MapNodeData
extends RefCounted

enum TipoNodo {COMBATE,ELITE,EVENTO,TIENDA,NOCHE_CABINA,JEFE}

var tipo:TipoNodo
var bioma: int
var posicion:Vector2
var nodos_siguientes:Array=[]
var completado: bool=false
var datos_extra:Dictionary={}

func _init(t:TipoNodo,b:int, pos:Vector2=Vector2.ZERO) -> void:
	tipo=t
	bioma=b
	posicion=pos
