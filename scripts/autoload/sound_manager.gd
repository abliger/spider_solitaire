extends Node

@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

var sfx_paths := {
	"deal": "res://assets/sounds/deal.wav",
	"move": "res://assets/sounds/move.wav",
	"flip": "res://assets/sounds/flip.wav",
	"error": "res://assets/sounds/error.wav",
	"win": "res://assets/sounds/win.wav",
	"click": "res://assets/sounds/click.wav"
}

var sfx_cache := {}

func _ready() -> void:
	add_child(sfx_player)
	add_child(music_player)
	music_player.bus = "Music"
	sfx_player.bus = "SFX"
	_preload_sfx()

func _preload_sfx() -> void:
	for key in sfx_paths:
		var stream = load(sfx_paths[key])
		if stream:
			sfx_cache[key] = stream

func play_sfx(sfx_name: String) -> void:
	if not SettingsData.sound_enabled:
		return
	if sfx_cache.has(sfx_name):
		var player := AudioStreamPlayer.new()
		player.stream = sfx_cache[sfx_name]
		player.bus = "SFX"
		add_child(player)
		player.play()
		player.finished.connect(func(): player.queue_free())

func play_music(music_name: String) -> void:
	if not SettingsData.music_enabled:
		return
	var path := "res://assets/sounds/%s.ogg" % music_name
	if ResourceLoader.exists(path):
		music_player.stream = load(path)
		music_player.play()

func stop_music() -> void:
	music_player.stop()
