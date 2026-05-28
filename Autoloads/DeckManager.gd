extends Node

var mazo: Array[CardData]=[] #cartas sin robar 
var mano: Array[CardData]=[]# carta en mano
var descarte: Array[CardData]=[]#cartas jugadas
var coleccion: Array[CardData]=[]#Todas

signal mano_actual(nueva_mano:Array)
signal mazo_actualizado(cartas_restantes:Array)

func iniciar_combate(mazo_full:Array[CardData])->void:
	coleccion=mazo_full.duplicate()
	mazo = coleccion.duplicate()
	mano.clear()
	descarte.clear()
	_mezclar(mazo)
	mazo_actualizado.emit(mazo.size())

func robar_cartas(cantidad:int)->int:
	var robadas:int=0
	for i in cantidad:
		if mazo.is_empty():
			if descarte.is_empty():
				break
			_reciclar_descarte()
		if not mazo.is_empty():
			mano.append(mazo.pop_back())
			robadas+=1
	mano_actual.emit(mano)
	mazo_actualizado.emit(mazo.size())
	return robadas

func descartar_carta(datos:CardData)->void:
	mano.erase(datos)
	descarte.append(datos)
	mano_actual.emit(mano)
func descartar_mano_full()->void:
	descarte.append_array(mano)
	mano.clear()
	mano_actual.emit(mano)
func _reciclar_descarte() ->void:
	mazo=descarte.duplicate()
	descarte.clear()
	_mezclar(mazo)
	print("RESET")
# ALGORITMO PA MEZCLAR
func _mezclar(lista:Array)->void:
	for i in range(lista.size()-1,0,1):
		var j = randi()%(i+1)
		var temp=lista[i]
		lista[i]=lista[j]
		lista[j]=temp
#PODER Y EXHAUST
func exiliar_carta(carta:CardData)->void:
	mano.erase(carta)
	mazo_actualizado.emit(mazo.size())
