extends Node

@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()    # 音效播放器 / SFX audio player
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

func _ready() -> void:
	# 将播放器节点添加到场景树并分配到对应音频总线
	add_child(sfx_player)
	add_child(music_player)
	music_player.bus = "Music"
	sfx_player.bus = "SFX"
	_preload_sfx()

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
	if sfx_cache.has(sfx_name):
		# 为每个音效创建独立播放器，避免打断正在播放的音效
		var player := AudioStreamPlayer.new()
		player.stream = sfx_cache[sfx_name]
		player.bus = "SFX"
		add_child(player)
		player.play()
		# 播放完毕后自动释放播放器节点
		player.finished.connect(func(): player.queue_free())

func play_music(music_name: String) -> void:
	# 播放指定名称的背景音乐；若音乐关闭则直接返回
	if not SettingsData.music_enabled:
		return
	var path := "res://assets/sounds/%s.ogg" % music_name
	if ResourceLoader.exists(path):
		music_player.stream = load(path)
		music_player.play()

func stop_music() -> void:
	# 停止背景音乐播放
	music_player.stop()
