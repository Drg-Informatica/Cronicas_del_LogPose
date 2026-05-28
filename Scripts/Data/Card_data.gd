class_name CardData

extends Resource

#Tipos d Esencia 
enum Esencia {FURIA,COLOSO,DERIVA,DOMINACION}

#TIPOS DE EFECTOS 
enum TipoEfecto {DAMAGE,DEFENSE,DRAW_CARD,HEAL,WEAKNESS,POISON,STRENGHT,VULNERABLE,STUN,GANAR_ENERGIA}

enum TipoCarta {ATAQUE,SKILL,POWER}
#Rareza
enum Rareza {COMUN,NOCOMUN,RARA}

@export var nombre: String = "Carta Sin Nombre"
@export_multiline() var descripcion: String= "Sin Descricion"
@export var coste_energia: int=1 
@export var esencia: Esencia=Esencia.FURIA 
@export var tipo_efecto: TipoEfecto=TipoEfecto.DAMAGE
@export var valor: int=0  #Damage o Defense o draw card
@export var tipo_efecto_2:TipoEfecto=TipoEfecto.DAMAGE
@export var valor_2:int=0
@export var imagen: Texture2D  #Arte de la carta 
@export var icon_type: Texture2D     # icono pequeño del tipo 
@export var better: bool = false
@export var rareza: Rareza=Rareza.COMUN



@export var tipo_carta: TipoCarta=TipoCarta.ATAQUE
#EXHAUST true desasparece al jugarse una vez
@export var exhaust: bool=false
# numero de golpes 
@export var ostias: int=1
var ruta_origen:String=""
