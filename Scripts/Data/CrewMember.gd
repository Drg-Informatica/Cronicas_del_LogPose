class_name CrewMemberData

extends Resource

enum Rol {CORSARIO,HERALDO,TIMONEL,NONAME}# DIFERENTE TRIPULANTES

@export var nombre:String="Tripulante"
@export var rol: Rol=Rol.CORSARIO
@export var esencia_aportada:CardData.Esencia=CardData.Esencia.FURIA
@export var descripcion:String=""
@export var portrait: Texture2D
@export var poder_nombre:String=""
@export_multiline var poder_descripcion:String=""
#DEspertar
@export var condicion_despertar:String=""
@export var habilidad_despertar_duracion:int=2
@export var cartas_regalo: Array[String] = []
var poder_usado: bool=false
var despertado: bool=false
enum TipoPoderCiclico { NINGUNO, DAMAGE, DRAW, HEAL, DEFENSE, MIXTO_FURIA }

@export var poder_ciclico_tipo: TipoPoderCiclico = TipoPoderCiclico.NINGUNO
@export var poder_ciclico_valor: int = 0          # daño, cartas a robar, HP a curar, bloqueo
@export var poder_ciclico_cada_n_turnos: int = 3  # frecuencia (1 = cada turno, 3 = cada 3 turnos)
@export var poder_ciclico_nombre: String = ""     # texto para el LblFeedbackPoder
func activar_despertar()->void:
	if not despertado:
		despertado=true
		print(nombre+"Ha Despertado Su PODER")

func resetear_poder()->void:
	despertado=false
