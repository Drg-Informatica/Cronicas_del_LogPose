extends Node

@onready var btn_nueva_partida:Button=$CanvasLayer/VBoxContainer/BtnNuevaPartida
@onready var btn_continuar:Button=$CanvasLayer/VBoxContainer/BtnContinuar
@onready var btn_salir:Button=$CanvasLayer/VBoxContainer/BtnSalir
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	btn_nueva_partida.pressed.connect(_on_nueva_partida)
	btn_continuar.pressed.connect(_on_continuar)
	btn_salir.pressed.connect(_on_salir)
	btn_continuar.visible=FileAccess.file_exists(GameState.RUTA_GUARDADO_RUN)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_nueva_partida()->void:
	get_tree().change_scene_to_file("res://scenes/ui/CaptainSelectionScene.tscn")

	#FALTA RELLENAR
func _on_continuar()->void:
	if GameState.cargar_run():
		get_tree().change_scene_to_file("res://Scenes/Map/MapScene.tscn")
	else:
		push_warning("NO SE PUDO CARGAR LA PARTIDA GUARDADA-SE BORRA SORRY>>>")
		GameState.eliminar_guardado_run()
		btn_continuar.visible=false
func _on_salir()->void:
	get_tree().quit()
