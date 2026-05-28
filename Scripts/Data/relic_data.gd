class_name RelicData
extends Resource

enum TriggerTipo{
	INICIO_COMBATE,
	INICIO_TURNO,
	MATA_ENEMIGO,
	RECIBE_DAMAGE,
	PASIVA,
}
@export var nombre:String=""
@export_multiline var descripcion:String=""
@export var imagen:Texture2D
@export var trigger:TriggerTipo=TriggerTipo.INICIO_TURNO
@export var valor:int=0

static func crear_espueala_de_capitan()->RelicData:
	var r = RelicData.new()
	r.nombre="Espuela Del Capitan"
	r.descripcion="al inicio de tu turno,si tienes 3 o mas cartas, gana 1 Fuerza"
	r.trigger=TriggerTipo.INICIO_TURNO
	r.valor=1
	return r
static func crear_fragmento_poneglyph()->RelicData:
	var r = RelicData.new()
	r.nombre="Fragmento de Poneglyph"
	r.descripcion="Al innicio de cada bioma,el Capitan gana +10 HP maximo permanente"
	r.trigger=TriggerTipo.PASIVA
	r.valor=10
	return r
static func crear_amuleto_de_coral()->RelicData:
	var r = RelicData.new()
	r.nombre="Amuleto de Coral"
	r.descripcion="Al innicio de cada combate,gana 5 de bloqueo"
	r.trigger=TriggerTipo.INICIO_COMBATE
	r.valor=5
	return r
