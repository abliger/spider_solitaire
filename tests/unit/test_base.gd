extends "res://addons/gut/test.gd"


## 测试基类，负责管理 Autoload 单例的生命周期。
## 在 GUT 中 Autoload 不会自动加载，需要手动注册到 Engine。

var _autoloads: Dictionary = {}


func _register_autoload(name: String, path: String) -> Node:
	if Engine.has_singleton(name):
		var existing = Engine.get_singleton(name)
		if is_instance_valid(existing):
			return existing

	var script: GDScript = load(path) as GDScript
	var node: Node = Node.new()
	node.set_script(script)
	node.name = name
	add_child(node)
	Engine.register_singleton(name, node)
	_autoloads[name] = node
	return node


func _unregister_autoloads() -> void:
	for name in _autoloads:
		if Engine.has_singleton(name):
			Engine.unregister_singleton(name)
		var node: Node = _autoloads[name]
		if is_instance_valid(node):
			node.queue_free()
	_autoloads.clear()
