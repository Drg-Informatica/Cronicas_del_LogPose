class_name EnemyData
extends Resource

class Intenciones:
	var nombre:String
	var tipo:String
	var valor: int
	var descripcion: String
	
	func _init(n:String,t:String,v:int,d:String) -> void:
		nombre=n;tipo=t;valor=v;descripcion=d

@export var nombre:String="enemigos"
@export var hp_maximo:int=65
@export var bloqueo_base:int=0
@export var esencia: CardData.Esencia=CardData.Esencia.FURIA
@export var imagen:Texture2D
@export var sprite_scale: Vector2 = Vector2(1.0, 1.0)
@export var flip_h: bool = false   
@export_multiline var descripcion_lore:String="" 
#LISTA INTENCIONES
@export var patron:Array=[]
@export var hp_umbral_fase2:int=0
@export var patron_fase2:Array=[]
@export var bloqueo_transicion_fase2: int=0


func get_intencion_turno(turno:int)->Dictionary:
	if patron.is_empty():
		return{}
	var indice =(turno-1)%patron.size()
	return patron[indice]

static func crear_grumete_rabioso()->EnemyData:
	var e = EnemyData.new()
	e.nombre="Grumete Rabioso"
	e.imagen = preload("res://Assets/Sprites/enemies/6.png")
	e.flip_h=true
	e.hp_maximo=65
	e.esencia=CardData.Esencia.FURIA
	e.patron=[
		{"nombre":"Golpe","tipo":"ataque","valor":10,"descripcion":"Pega de 10"},
		{"nombre":"Golpe","tipo":"ataque","valor":10,"descripcion":"Pega de 10"},
		{"nombre":"Golpe fuerte","tipo":"ataque","valor":20,"descripcion":"Pega de 20"},
	]
	return e
static func crear_marinero_de_abordaje() -> EnemyData:
	var e = EnemyData.new()
	e.nombre = "Marinero de Abordaje"
	e.hp_maximo = 90
	e.esencia = CardData.Esencia.FURIA
	e.imagen = preload("res://Assets/Sprites/enemies/3.png")
	e.flip_h=true
	e.patron = [
		{"nombre": "Golpe",        "tipo": "ataque",  "valor": 12, "descripcion": "Ataca por 12"},
		{"nombre": "Abordaje",     "tipo": "ataque",  "valor": 18, "descripcion": "Ataca por 18"},
		{"nombre": "Golpe Doble",  "tipo": "ataque",  "valor": 12, "descripcion": "Ataca dos veces por 12"},
	]
	return e
static func crear_lugarteniente() -> EnemyData:
	var e = EnemyData.new()
	e.nombre = "Lugarteniente"
	e.hp_maximo = 160
	e.imagen = preload("res://Assets/Sprites/enemies/12.png")
	e.flip_h=true
	e.esencia = CardData.Esencia.COLOSO
	e.patron = [
		{"nombre": "Golpe Pesado",  "tipo": "ataque",   "valor": 22, "descripcion": "Ataca por 22"},
		{"nombre": "Defensa",       "tipo": "bloqueo",  "valor": 15, "descripcion": "Gana 15 de Bloqueo"},
		{"nombre": "Golpe Pesado",  "tipo": "ataque",   "valor": 22, "descripcion": "Ataca por 22"},
		{"nombre": "Carga",         "tipo": "ataque",   "valor": 30, "descripcion": "Ataca por 30"},
	]
	return e
static func crear_corsario_de_la_corona() -> EnemyData:
	var e = EnemyData.new()
	e.nombre = "Corsario de la Corona"
	e.imagen = preload("res://Assets/Sprites/enemies/1.png")
	e.flip_h=true
	e.hp_maximo = 380
	e.hp_umbral_fase2 = 190
	e.bloqueo_transicion_fase2 = 30
	e.patron = [
		{"nombre": "Estocada Real",   "tipo": "ataque",   "valor": 28},
		{"nombre": "Escudo Real",     "tipo": "defensa",  "valor": 20},
		{"nombre": "Doble Estocada",  "tipo": "ataque",   "valor": 18, "golpes": 2},
		{"nombre": "Decreto Marcial", "tipo": "debilitar","valor": 2},
	]
	e.patron_fase2 = [
		{"nombre": "Furia del Rey",     "tipo": "ataque_penetrante", "valor": 35},
		{"nombre": "Voluntad de Hierro","tipo": "defensa_curacion",  "valor": 25, "curacion": 15},
		{"nombre": "Condena Real",      "tipo": "ataque",            "valor": 22},
]
	return e
	
