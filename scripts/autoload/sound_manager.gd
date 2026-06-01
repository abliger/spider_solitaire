extends Node

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()  # 音乐播放器 / Music audio player

# 音效资源路径映射 / SFX resource path mapping
var sfx_paths := {
	"deal": "res://assets/sounds/deal.wav",   # 发牌音效
	"move": "res://assets/sounds/move.wav",   # 移动音效
	"flip": "res://assets/sounds/flip.wav",   # 翻牌音效
	"error": "res://assets/sounds/error.wav", # 错误音效
	"win": "res://assets/sounds/win.wav",     # 胜利音效
	"click": "res://assets/sounds/click.wav"  # 点击音效
}

var sfx_cache := {}  # 预加载的音效资源缓存 / Preloaded SFX stream cache

# SFX 播放器节点池（上限 8 个，复用以减少频繁创建/销毁节点）/ SFX player pool
const MAX_SFX_POOL_SIZE := 8
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0

func _ready() -> void:
	add_child(music_player)
	music_player.bus = "Music"
	_preload_sfx()
	# 预创建 SFX 播放器池
	for i in range(MAX_SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

func _preload_sfx() -> void:
	# 预加载所有音效资源到缓存，避免运行时重复加载
	for key in sfx_paths:
		var stream = load(sfx_paths[key])
		if stream:
			sfx_cache[key] = stream

func play_sfx(sfx_name: String) -> void:
	# 播放指定名称的音效；若音效关闭则直接返回
	if not SettingsData.sound_enabled:
		return
	if not sfx_cache.has(sfx_name):
		return
	# 从池中获取播放器并轮换索引
	var player := _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % MAX_SFX_POOL_SIZE
	player.stream = sfx_cache[sfx_name]
	player.play()

func play_music(music_name: String) -> void:
	# 播放指定名称的背景音乐；若音乐关闭或已在播放则直接返回
	if not SettingsData.music_enabled:
		return
	var path := "res://assets/sounds/%s.ogg" % music_name
	if ResourceLoader.exists(path):
		var stream := load(path) as AudioStream
		if music_player.stream == stream and music_player.playing:
			return
		music_player.stream = stream
		music_player.play()

func stop_music() -> void:
	# 停止背景音乐播放
	music_player.stop()
