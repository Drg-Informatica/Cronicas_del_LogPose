class_name CptnData
extends Resource

@export var nombre: String="Capitan NONAME"
@export var esencia: CardData.Esencia=CardData.Esencia.FURIA
@export var hp_maximo: int=80 
@export	var energia_por_turno: int=3
@export var poder_nombre: String=""
@export var full_art:Texture2D
@export var portrait: Texture2D  
@export_multiline var poder_descripcion: String=""
@export var color_acento: Color = Color.WHITE 
# Ruta a las cartas del mazo inicial 
@export var rutas_mazo_inicial: Array[String]=[]

static func crear_kael_el_errante() -> CptnData:
	var c = CptnData.new()
	c.nombre = "Kael, el Errante"
	c.full_art=preload("res://Assets/Sprites/captains/CapitanRetratos.tres")
	c.portrait=preload("res://Assets/Sprites/captains/CapitanRetratos.tres")
	c.esencia = CardData.Esencia.FURIA
	c.hp_maximo = 80
	c.energia_por_turno = 3
	c.poder_nombre = "Impacto"
	c.poder_descripcion = "Tus Ataques tienen un 30% de Aturdir al Enemigo"
	var rutas: Array[String] = [
		"res://Resources/Cards/Furia/Arremeter.tres",
		"res://Resources/Cards/Furia/Arremeter.tres",
		"res://Resources/Cards/Furia/Arremeter.tres",
		"res://Resources/Cards/Furia/Arremeter.tres",
		"res://Resources/Cards/Furia/Estocada.tres",
		"res://Resources/Cards/Furia/Estocada.tres",
		"res://Resources/Cards/Furia/Estocada.tres",
		"res://Resources/Cards/Furia/Estocada.tres",
		"res://Resources/Cards/Furia/Golpe_De_Abordaje.tres",
		"res://Resources/Cards/Furia/Rugido.tres",
	]
	c.rutas_mazo_inicial = rutas
	return c


static func crear_petra_la_colosa() -> CptnData:
	var c = CptnData.new()
	c.nombre = "Petra, la Colosa"
	c.full_art=preload("res://Assets/Sprites/captains/Petra.tres")
	c.portrait=preload("res://Assets/Sprites/captains/Petra.tres")
	c.esencia = CardData.Esencia.COLOSO
	c.hp_maximo = 90
	c.energia_por_turno = 3
	c.poder_nombre = "Resiliencia"
	c.poder_descripcion = "Al inicio de cada turno, ganas 3 puntos de Bloqueo de forma gratuita."
	var rutas: Array[String] = [
		"res://Resources/Cards/Coloso/Postura_de_roca.tres",
		"res://Resources/Cards/Coloso/Postura_de_roca.tres",
		"res://Resources/Cards/Coloso/Postura_de_roca.tres",
		"res://Resources/Cards/Coloso/Postura_de_roca.tres",
		"res://Resources/Cards/Coloso/Coraza.tres",
		"res://Resources/Cards/Coloso/Coraza.tres",
		"res://Resources/Cards/Coloso/Coraza.tres",
		"res://Resources/Cards/Coloso/Coraza.tres",
		"res://Resources/Cards/Coloso/Aguante.tres",
		"res://Resources/Cards/Coloso/Trinchera.tres",
	]
	c.rutas_mazo_inicial = rutas
	return c


static func crear_lyra_de_la_deriva() -> CptnData:
	var c = CptnData.new()
	c.nombre = "Lyra, de la Deriva"
	c.full_art=preload("res://Assets/Sprites/captains/Pietro.tres")
	c.portrait=preload("res://Assets/Sprites/captains/Pietro.tres")
	c.esencia = CardData.Esencia.DERIVA
	c.hp_maximo = 70
	c.energia_por_turno = 3
	c.poder_nombre = "Flujo de Marea"
	c.poder_descripcion = "Cuando robas 2 o más cartas en un solo efecto, ganas 1 punto de energía."
	var rutas: Array[String] = [
		"res://Resources/Cards/Deriva/Corriente_lateral.tres",
		"res://Resources/Cards/Deriva/Corriente_lateral.tres",
		"res://Resources/Cards/Deriva/Corriente_lateral.tres",
		"res://Resources/Cards/Deriva/Corriente_lateral.tres",
		"res://Resources/Cards/Deriva/Brisa_marina.tres",
		"res://Resources/Cards/Deriva/Brisa_marina.tres",
		"res://Resources/Cards/Deriva/Brisa_marina.tres",
		"res://Resources/Cards/Deriva/Brisa_marina.tres",
		"res://Resources/Cards/Deriva/Marea_favorable.tres",
		"res://Resources/Cards/Deriva/Viento_en_popa.tres",
	]
	c.rutas_mazo_inicial = rutas
	return c
# cargar y duplicar Cartas 
func crear_mazo_inicial() -> Array[CardData]:
	var mazo: Array[CardData] = []
	push_warning("[CPTN] Creando mazo inicial para " + nombre + " con " + str(rutas_mazo_inicial.size()) + " rutas")
	for ruta in rutas_mazo_inicial:
		var carta = load(ruta) as CardData
		if carta:
			var copia = carta.duplicate()
			copia.ruta_origen = ruta
			mazo.append(copia)
		else:
			push_error("[CPTN] No se pudo cargar la carta: " + ruta)
	push_warning("[CPTN] Mazo creado con " + str(mazo.size()) + " cartas")
	return mazo
