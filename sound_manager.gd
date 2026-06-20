extends Node
## SoundManager — Procedural audio synthesis with multiple selectable themes.
## Registered as Autoload so any script can call SoundManager.play_click() etc.

signal theme_changed(theme_name: String)

# Available sound themes
enum SoundTheme { MECHANICAL_BLUE, MECHANICAL_BROWN, TAIKO, BARK }

const THEME_NAMES: Array[String] = ["青轴机械 (Blue)", "茶轴机械 (Brown)", "太鼓 (Taiko)", "汪汪 (Bark)"]
const THEME_KEYS: Array[String] = ["mechanical_blue", "mechanical_brown", "taiko", "bark"]

var current_theme: int = SoundTheme.MECHANICAL_BLUE

# Pre-baked sound buffers per theme: { theme_key: { "click": AudioStreamWAV, "tap": AudioStreamWAV } }
var _sound_banks: Dictionary = {}

const MIX_RATE: int = 22050

func _ready() -> void:
	_bake_all_themes()

# ─── Public API ───────────────────────────────────────────────

func play_click(excitement: float = 0.0) -> void:
	var bank = _sound_banks.get(THEME_KEYS[current_theme], null)
	if bank:
		_play(bank["click"], excitement)

func play_tap(excitement: float = 0.0) -> void:
	var bank = _sound_banks.get(THEME_KEYS[current_theme], null)
	if bank:
		_play(bank["tap"], excitement)

func play_bark(excitement: float = 0.0) -> void:
	# Always use the bark theme's click sound for explicit bark calls
	var bank = _sound_banks.get("bark", null)
	if bank:
		_play(bank["click"], excitement)

func set_theme(index: int) -> void:
	if index >= 0 and index < THEME_KEYS.size():
		current_theme = index
		theme_changed.emit(THEME_KEYS[index])

func get_theme_index() -> int:
	return current_theme

func get_theme_names() -> Array[String]:
	return THEME_NAMES

# ─── Internal Playback ────────────────────────────────────────

func _play(stream: AudioStreamWAV, excitement: float) -> void:
	if not stream:
		return
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.pitch_scale = randf_range(0.93, 1.07) + excitement * 0.3
	player.volume_db = -6.0
	player.play()
	player.finished.connect(func():
		player.queue_free()
	)

# ─── Waveform Synthesis ──────────────────────────────────────

func _bake_all_themes() -> void:
	_sound_banks["mechanical_blue"] = {
		"click": _bake_mechanical_blue_click(),
		"tap": _bake_mechanical_blue_tap()
	}
	_sound_banks["mechanical_brown"] = {
		"click": _bake_mechanical_brown_click(),
		"tap": _bake_mechanical_brown_tap()
	}
	_sound_banks["taiko"] = {
		"click": _bake_taiko_click(),
		"tap": _bake_taiko_tap()
	}
	_sound_banks["bark"] = {
		"click": _bake_bark_click(),
		"tap": _bake_bark_tap()
	}

## Blue axis: sharp, high-pitched clicky feel
func _bake_mechanical_blue_click() -> AudioStreamWAV:
	var dur = 0.04
	var n = int(MIX_RATE * dur)
	var buf = PackedByteArray()
	buf.resize(n * 2)
	for i in range(n):
		var t = float(i) / MIX_RATE
		# Sharp click: high-freq sine burst + white noise, fast decay
		var v = (sin(2.0 * PI * 2400.0 * t) * 0.5 + randf_range(-0.3, 0.3)) * exp(-t * 180.0)
		buf.encode_s16(i * 2, int(clamp(v * 32767.0, -32768.0, 32767.0)))
	return _make_wav(buf)

func _bake_mechanical_blue_tap() -> AudioStreamWAV:
	var dur = 0.06
	var n = int(MIX_RATE * dur)
	var buf = PackedByteArray()
	buf.resize(n * 2)
	for i in range(n):
		var t = float(i) / MIX_RATE
		# Bottom-out thud after the click
		var v = (sin(2.0 * PI * 800.0 * t) * 0.4 + randf_range(-0.2, 0.2)) * exp(-t * 100.0)
		buf.encode_s16(i * 2, int(clamp(v * 32767.0, -32768.0, 32767.0)))
	return _make_wav(buf)

## Brown axis: softer, muted tactile bump
func _bake_mechanical_brown_click() -> AudioStreamWAV:
	var dur = 0.05
	var n = int(MIX_RATE * dur)
	var buf = PackedByteArray()
	buf.resize(n * 2)
	for i in range(n):
		var t = float(i) / MIX_RATE
		# Softer thud with mid-frequency sine
		var v = (sin(2.0 * PI * 1200.0 * t) * 0.35 + randf_range(-0.15, 0.15)) * exp(-t * 130.0)
		buf.encode_s16(i * 2, int(clamp(v * 32767.0, -32768.0, 32767.0)))
	return _make_wav(buf)

func _bake_mechanical_brown_tap() -> AudioStreamWAV:
	var dur = 0.08
	var n = int(MIX_RATE * dur)
	var buf = PackedByteArray()
	buf.resize(n * 2)
	for i in range(n):
		var t = float(i) / MIX_RATE
		var v = sin(2.0 * PI * 400.0 * t) * 0.3 * exp(-t * 60.0)
		buf.encode_s16(i * 2, int(clamp(v * 32767.0, -32768.0, 32767.0)))
	return _make_wav(buf)

## Taiko: warm bass drum resonance
func _bake_taiko_click() -> AudioStreamWAV:
	var dur = 0.2
	var n = int(MIX_RATE * dur)
	var buf = PackedByteArray()
	buf.resize(n * 2)
	for i in range(n):
		var t = float(i) / MIX_RATE
		# Low-freq sine with overtone, slow decay for resonance
		var fundamental = sin(2.0 * PI * 90.0 * t) * 0.6
		var overtone = sin(2.0 * PI * 180.0 * t) * 0.25
		var attack = min(t * 200.0, 1.0) # fast attack ramp
		var v = (fundamental + overtone) * attack * exp(-t * 12.0)
		buf.encode_s16(i * 2, int(clamp(v * 32767.0, -32768.0, 32767.0)))
	return _make_wav(buf)

func _bake_taiko_tap() -> AudioStreamWAV:
	var dur = 0.15
	var n = int(MIX_RATE * dur)
	var buf = PackedByteArray()
	buf.resize(n * 2)
	for i in range(n):
		var t = float(i) / MIX_RATE
		# Higher rim tap
		var v = (sin(2.0 * PI * 300.0 * t) * 0.4 + sin(2.0 * PI * 600.0 * t) * 0.2) * exp(-t * 25.0)
		buf.encode_s16(i * 2, int(clamp(v * 32767.0, -32768.0, 32767.0)))
	return _make_wav(buf)

## Bark: synthesized dog woof
func _bake_bark_click() -> AudioStreamWAV:
	var dur = 0.18
	var n = int(MIX_RATE * dur)
	var buf = PackedByteArray()
	buf.resize(n * 2)
	for i in range(n):
		var t = float(i) / MIX_RATE
		# Bark: frequency sweep down (formant-like) + noise burst
		var freq = 600.0 - t * 1500.0 # sweep from 600 down to ~330Hz
		var formant = sin(2.0 * PI * freq * t) * 0.5
		var noise = randf_range(-0.15, 0.15) * exp(-t * 20.0)
		var envelope = min(t * 100.0, 1.0) * exp(-t * 15.0)
		var v = (formant + noise) * envelope
		buf.encode_s16(i * 2, int(clamp(v * 32767.0, -32768.0, 32767.0)))
	return _make_wav(buf)

func _bake_bark_tap() -> AudioStreamWAV:
	var dur = 0.12
	var n = int(MIX_RATE * dur)
	var buf = PackedByteArray()
	buf.resize(n * 2)
	for i in range(n):
		var t = float(i) / MIX_RATE
		# Short yip
		var freq = 800.0 - t * 1000.0
		var v = sin(2.0 * PI * freq * t) * 0.4 * exp(-t * 25.0)
		buf.encode_s16(i * 2, int(clamp(v * 32767.0, -32768.0, 32767.0)))
	return _make_wav(buf)

# ─── Helpers ──────────────────────────────────────────────────

func _make_wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
