class_name CardUI
extends Control

const Colores_Esencia = {
	CardData.Esencia.FURIA: Color(0.8, 0.2, 0.006, 1.0),
	CardData.Esencia.COLOSO: Color(0.362, 0.746, 0.35, 1.0),
	CardData.Esencia.DERIVA: Color(0.169, 0.292, 0.848, 1.0),
	CardData.Esencia.DOMINACION: Color(0.662, 0.584, 0.146, 1.0),
}

@export var datos: CardData:
	set(valor):
		datos = valor
		if is_node_ready():
			reload_visual()

@onready var lbl_nombre: Label = $PanelContainer/VBoxContainer/HBoxContainer/Lbl_nombre
@onready var lbl_coste: Label = $PanelContainer/VBoxContainer/HBoxContainer/Lbl_coste
@onready var imagen_carta: TextureRect = $PanelContainer/VBoxContainer/ImagenCarta
@onready var lbl_esencia: Label = $PanelContainer/VBoxContainer/Lbl_Esencia
@onready var lbl_descripcion: Label = $PanelContainer/VBoxContainer/Lbl_Descripcion
@onready var icon_type_rect: TextureRect =$PanelContainer/VBoxContainer/HBoxContainer/IconType

signal carta_presionada(carta_ui: CardUI)
signal carta_soltada(carta_ui: CardUI, posicion: Vector2)

var en_mano: bool = true
var arrastrando: bool = false
var posicion_original: Vector2
var tween_hover: Tween


func _ready() -> void:
	# Asegurar tamaño mínimo para que el HBoxContainer separe las cartas
	custom_minimum_size = Vector2(160, 220)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	if datos:
		reload_visual()
	posicion_original = position
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func reload_visual() -> void:
	if datos == null:
		return
	lbl_nombre.text = datos.nombre
	# Coste teniendo en cuenta la marea actual
	var coste_real = GameState.marea.calcular_coste(datos) if GameState.marea else datos.coste_energia
	lbl_coste.text = str(coste_real)
	if coste_real < datos.coste_energia:
		lbl_coste.add_theme_color_override("font_color", Color.GREEN)
	elif coste_real > datos.coste_energia:
		lbl_coste.add_theme_color_override("font_color", Color.RED)
	else:
		lbl_coste.remove_theme_color_override("font_color")
	lbl_descripcion.text = datos.descripcion
	lbl_esencia.text = CardData.Esencia.keys()[datos.esencia]
	if datos.imagen:
		imagen_carta.texture = datos.imagen
	var color = Colores_Esencia.get(datos.esencia, Color.WHITE)
	$PanelContainer.self_modulate = color


func refresh_coste_visual(coste_modificado: int) -> void:
	$PanelContainer/VBoxContainer/HBoxContainer/Lbl_nombre.text = datos.nombre
	$PanelContainer/VBoxContainer/HBoxContainer/Lbl_coste.text = str(datos.coste_energia)
	$PanelContainer/VBoxContainer/Lbl_Descripcion.text= datos.descripcion
	$PanelContainer/VBoxContainer/Lbl_Esencia.text=CardData.TipoCarta.keys()[datos.tipo_carta]
	if datos.imagen:
		imagen_carta.texture = datos.imagen
	if datos.icon_type:
		icon_type_rect.texture = datos.icon_type


# Alias para que CombatManager lo encuentre con el nombre que usa
func actualizar_coste_visual(coste_modificado: int) -> void:
	refresh_coste_visual(coste_modificado)


func _on_mouse_entered() -> void:
	if not arrastrando:
		if tween_hover:
			tween_hover.kill()
		tween_hover = create_tween().set_parallel(true)
		tween_hover.tween_property(self, "position:y", posicion_original.y - 30, 0.15)
		tween_hover.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)


func _on_mouse_exited() -> void:
	if not arrastrando:
		if tween_hover:
			tween_hover.kill()
		tween_hover = create_tween().set_parallel(true)
		tween_hover.tween_property(self, "position:y", posicion_original.y, 0.15)
		tween_hover.tween_property(self, "scale", Vector2.ONE, 0.15)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not en_mano:
			# Modo selección (Reward, Tienda): solo click, no drag
			if event.pressed:
				carta_presionada.emit(self)
			return
		# Modo combate: drag and drop
		if event.pressed:
			_iniciar_drag()
		else:
			_finalizar_drag()
	elif event is InputEventMouseMotion and arrastrando:
		position += event.relative


func _iniciar_drag() -> void:
	arrastrando = true
	posicion_original = position
	z_index = 10
	if tween_hover:
		tween_hover.kill()
	scale = Vector2(1.1, 1.1)


func _finalizar_drag() -> void:
	arrastrando = false
	z_index = 0
	carta_soltada.emit(self, get_global_rect().get_center())
	var t = create_tween().set_parallel(true)
	t.tween_property(self, "position", posicion_original, 0.2)
	t.tween_property(self, "scale", Vector2.ONE, 0.2)
