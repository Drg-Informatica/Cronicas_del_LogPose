class_name StatusEffect
extends RefCounted

var vulnerable: int =0
var poison : int=0
var stun : bool=false
var strenght:int=0
var weak: int=0

func tiene_vulnerable() ->bool:
	return vulnerable>0

#Damage real Aplicando Vulnerable
func calcular_damage_recibido(damage:int) ->int:
	if tiene_vulnerable():
		return int(damage*1.5)
	return damage

#CAlcular Fuerza y debil 
func calcular_damage_enviado(damage_base:int)->int:
	var total = damage_base + strenght
	if weak > 0 :
		total= int(total*0.75)
	return total

func al_actuar()->void:
	if vulnerable>0:
		vulnerable-=1
	if weak>0:
		weak-=1
	strenght=0 
#Poison veneno tick
func procesar_poison()->int:
	var damage=poison
	if poison>0:
		poison-=1
	return damage
#STuneado
func puede_actuar()->bool:
	if stun:
		stun=false
		return false
	return true
# Resetear 
func reset_combat()->void:
	vulnerable=0
	poison=0
	strenght=0
	stun=0
	weak=0
