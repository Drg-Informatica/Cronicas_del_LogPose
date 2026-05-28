extends Node

# ── Diccionario de efectos de sonido ──────────────────────────────────────
# Clave: nombre lógico del efecto | Valor: ruta al recurso de audio
const SFX: Dictionary = {
	# Cartas
	"carta_robar":       "res://assets/audio/sfx/card_draw.wav",
	"carta_jugar":       "res://assets/audio/sfx/card_play.wav",
	"carta_descartar":   "res://assets/audio/sfx/card_discard.wav",
	"carta_hover":       "res://assets/audio/sfx/card_hover.wav",
	# Combate
	"golpe_normal":      "res://assets/audio/sfx/hit_normal.wav",
	"golpe_critico":     "res://assets/audio/sfx/hit_critical.wav",
	"bloqueo":           "res://assets/audio/sfx/block.wav",
	"enemigo_muere":     "res://assets/audio/sfx/enemy_death.wav",
	"jugador_danio":     "res://assets/audio/sfx/player_hurt.wav",
	# Habilidades especiales
	"poder_activar":     "res://assets/audio/sfx/power_activate.wav",
	"marea_cambio":      "res://assets/audio/sfx/tide_change.wav",
	# Mapa y navegación
	"nodo_seleccionar":  "res://assets/audio/sfx/node_select.wav",
	"nodo_hover":        "res://assets/audio/sfx/node_hover.wav",
	# UI general
	"boton_click":       "res://assets/audio/sfx/button_click.wav",
	"boton_hover":       "res://assets/audio/sfx/button_hover.wav",
	"recompensa_oro":    "res://assets/audio/sfx/coin.wav",
	"victoria":          "res://assets/audio/sfx/victory.wav",
	"derrota":           "res://assets/audio/sfx/defeat.wav",
	# Reliquia
	"reliquia_obtener":  "res://assets/audio/sfx/relic_pickup.wav",
}

# ── Diccionario de música de fondo ────────────────────────────────────────
const BGM: Dictionary = {
	"menu_principal":    "res://assets/audio/bgm/main_menu.ogg",
	"mapa_navegacion":   "res://assets/audio/bgm/map_theme.ogg",
	"combate_normal":    "res://assets/audio/bgm/combat_normal.ogg",
	"combate_boss":      "res://assets/audio/bgm/combat_boss.ogg",
	"tienda":            "res://assets/audio/bgm/shop_theme.ogg",
	"victoria":          "res://assets/audio/bgm/victory.ogg",
	"game_over":         "res://assets/audio/bgm/game_over.ogg",
}

# ── Referencias a nodos ───────────────────────────────────────────────────
@onready var music_player: AudioStreamPlayer  = $MusicPlayer
@onready var sfx_players: Array[AudioStreamPlayer] = [
	$SfxPlayer, $SfxPlayer2, $SfxPlayer3
]
@onready var ui_player: AudioStreamPlayer = $UiPlayer

var _sfx_index: int = 0
var _bgm_actual: String = ""
var _sfx_cache: Dictionary = {}
var _bgm_cache: Dictionary = {}
var _fade_tween: Tween = null

# ── Señales ───────────────────────────────────────────────────────────────
signal bgm_cambiada(nombre: String)

# ─────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_precargar_sfx_criticos()

func _precargar_sfx_criticos() -> void:
	var criticos := ["carta_robar", "carta_jugar", "golpe_normal", "boton_click"]
	for key in criticos:
		if SFX.has(key):
			var stream: AudioStream = load(SFX[key])
			if stream:
				_sfx_cache[key] = stream

# ─────────────────────────────────────────────────────────────────────────
# MÚSICA DE FONDO
# ─────────────────────────────────────────────────────────────────────────
func play_bgm(nombre: String, fade_out_seg: float = 0.5) -> void:
	if nombre == _bgm_actual:
		return
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if music_player.playing and fade_out_seg > 0.0:
		_fade_tween = create_tween()
		_fade_tween.tween_property(music_player, "volume_db", -60.0, fade_out_seg)
		await _fade_tween.finished
	_bgm_actual = nombre
	if not BGM.has(nombre):
		push_warning("AudioManager: BGM no encontrada — " + nombre)
		return
	if not _bgm_cache.has(nombre):
		_bgm_cache[nombre] = load(BGM[nombre])
	music_player.stream = _bgm_cache[nombre]
	music_player.volume_db = 0.0
	music_player.play()
	bgm_cambiada.emit(nombre)

func stop_bgm(fade_out_seg: float = 1.0) -> void:
	if not music_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(music_player, "volume_db", -60.0, fade_out_seg)
	await tween.finished
	music_player.stop()
	_bgm_actual = ""

# ─────────────────────────────────────────────────────────────────────────
# EFECTOS DE SONIDO
# ─────────────────────────────────────────────────────────────────────────
func play_sfx(nombre: String, volumen_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream: AudioStream
	if _sfx_cache.has(nombre):
		stream = _sfx_cache[nombre]
	elif SFX.has(nombre):
		stream = load(SFX[nombre])
		_sfx_cache[nombre] = stream
	else:
		push_warning("AudioManager: SFX no encontrado — " + nombre)
		return
	var player := sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % sfx_players.size()
	player.stream = stream
	player.volume_db = volumen_db
	player.pitch_scale = pitch
	player.play()

func play_sfx_ui(nombre: String, volumen_db: float = 0.0) -> void:
	var stream: AudioStream
	if _sfx_cache.has(nombre):
		stream = _sfx_cache[nombre]
	elif SFX.has(nombre):
		stream = load(SFX[nombre])
		_sfx_cache[nombre] = stream
	else:
		push_warning("AudioManager: SFX UI no encontrado — " + nombre)
		return
	ui_player.stream = stream
	ui_player.volume_db = volumen_db
	ui_player.play()

# Variación aleatoria de pitch para que los sonidos no suenen repetitivos
func play_sfx_variado(nombre: String, pitch_min: float = 0.9, pitch_max: float = 1.1) -> void:
	var pitch := randf_range(pitch_min, pitch_max)
	play_sfx(nombre, 0.0, pitch)

# ─────────────────────────────────────────────────────────────────────────
# VOLUMEN
# ─────────────────────────────────────────────────────────────────────────
func set_volumen_master(valor_0_1: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(valor_0_1)
	)

func set_volumen_musica(valor_0_1: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(valor_0_1)
	)

func set_volumen_sfx(valor_0_1: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(valor_0_1)
	)
