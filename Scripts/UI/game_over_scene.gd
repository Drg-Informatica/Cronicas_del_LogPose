class_name GameOverScene
extends Node

@onready var btn_menu: Button = $CanvasLayer/Panel/VBox/BtnMenu

func _ready() -> void:
	#AudioManager.play_bgm("game_over", 0.5)
	#AudioManager.play_sfx("derrota")
	btn_menu.pressed.connect(_on_btn_menu_pressed)

func _on_btn_menu_pressed() -> void:
	# on_run_completada(false) guarda la meta-progresión (logros, monedas)
	# borra el save del run actual y navega al MainMenu.
	GameState.on_ruta_completada(false)
