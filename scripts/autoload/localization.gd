extends Node

## 为所有 UI 文本提供字符串翻译的单例。

signal locale_changed  # 语言切换时发出 / Emitted when the active locale changes

const FALLBACK_LOCALE := "en"  # 默认回退语言 / Fallback locale when translation is missing

var _current_locale: String = FALLBACK_LOCALE  # 当前激活的语言 / Currently active locale

# 翻译字典：支持英文和中文 / Translation dictionary supporting English and Chinese
var _translations: Dictionary = {
	"en": {
		"title": "Spider Solitaire",
		"new_game": "New Game",
		"continue": "Continue",
		"settings": "Settings",
		"quit": "Quit",
		"select_difficulty": "Select Difficulty",
		"easy": "Easy (1 Suit)",
		"medium": "Medium (2 Suits)",
		"hard": "Hard (4 Suits)",
		"back": "Back",
		"paused": "Paused",
		"resume": "Resume",
		"restart": "Restart",
		"main_menu": "Main Menu",
		"score": "Score: %d",
		"time": "Time: %02d:%02d",
		"moves": "Moves: %d",
		"difficulty": "Difficulty: %s",
		"diff_easy": "Easy",
		"diff_medium": "Medium",
		"diff_hard": "Hard",
		"undo": "Undo",
		"hint": "Hint",
		"pause": "Pause",
		"you_won": "You Won!",
		"final_score": "Final Score: %d",
		"settings_title": "Settings",
		"sound_effects": "Sound Effects",
		"music": "Music",
		"default_difficulty": "Default Difficulty:",
		"language": "Language:",
		"fullscreen": "Fullscreen",
		"reset_best_scores": "Reset Best Scores",
		"stock_left": "%d left",
		"lang_en": "English",
		"lang_zh": "中文",
		"play_again": "Play Again",
	},
	"zh": {
		"title": "蜘蛛纸牌",
		"new_game": "新游戏",
		"continue": "继续",
		"settings": "设置",
		"quit": "退出",
		"select_difficulty": "选择难度",
		"easy": "简单（1 花色）",
		"medium": "中等（2 花色）",
		"hard": "困难（4 花色）",
		"back": "返回",
		"paused": "已暂停",
		"resume": "继续游戏",
		"restart": "重新开始",
		"main_menu": "主菜单",
		"score": "得分: %d",
		"time": "时间: %02d:%02d",
		"moves": "步数: %d",
		"difficulty": "难度: %s",
		"diff_easy": "简单",
		"diff_medium": "中等",
		"diff_hard": "困难",
		"undo": "撤销",
		"hint": "提示",
		"pause": "暂停",
		"you_won": "你赢了!",
		"final_score": "最终得分: %d",
		"settings_title": "设置",
		"sound_effects": "音效",
		"music": "音乐",
		"default_difficulty": "默认难度:",
		"language": "语言:",
		"fullscreen": "全屏",
		"reset_best_scores": "重置最高分",
		"stock_left": "剩余 %d",
		"lang_en": "English",
		"lang_zh": "中文",
		"play_again": "再玩一次",
	}
}


func _ready() -> void:
	# 启动时加载已保存的语言设置
	_current_locale = SettingsData.locale


## 返回给定键对应的翻译字符串。
## 如果未找到该键，则返回键本身作为回退。
func translate(key: String) -> String:
	var dict: Dictionary = _translations.get(_current_locale, {})
	return dict.get(key, key)


## 切换当前语言并发出 locale_changed 信号。
func set_locale(locale: String) -> void:
	if _current_locale == locale:
		return
	if not _translations.has(locale):
		return
	_current_locale = locale
	SettingsData.locale = locale
	locale_changed.emit()


## 返回当前的语言代码。
func get_locale() -> String:
	return _current_locale


## 返回支持的语言代码列表。
func get_supported_locales() -> Array:
	return _translations.keys().duplicate()


## 返回语言代码对应的显示名称。
func get_locale_display_name(locale: String) -> String:
	match locale:
		"en": return translate("lang_en")
		"zh": return translate("lang_zh")
		_: return locale
