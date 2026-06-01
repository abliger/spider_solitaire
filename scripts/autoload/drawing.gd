extends Node

## 跨节点共享的 CanvasItem 绘制辅助函数。

static func rounded_rect_fill(canvas: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	var r: float = min(radius, min(rect.size.x * 0.5, rect.size.y * 0.5))
	var inner := Rect2(rect.position + Vector2(r, 0), rect.size - Vector2(r * 2, 0))
	canvas.draw_rect(inner, color)
	var inner_v := Rect2(rect.position + Vector2(0, r), rect.size - Vector2(0, r * 2))
	canvas.draw_rect(inner_v, color)
	canvas.draw_circle(rect.position + Vector2(r, r), r, color)
	canvas.draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	canvas.draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)
	canvas.draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)


static func rounded_rect_outline(canvas: CanvasItem, rect: Rect2, radius: float, color: Color, width: float) -> void:
	var r: float = min(radius, min(rect.size.x * 0.5, rect.size.y * 0.5))
	var tl := rect.position + Vector2(r, r)
	var tr := rect.position + Vector2(rect.size.x - r, r)
	var br := rect.position + rect.size - Vector2(r, r)
	var bl := rect.position + Vector2(r, rect.size.y - r)

	canvas.draw_line(tl + Vector2(-r, 0), tr + Vector2(r, 0), color, width)
	canvas.draw_line(tr + Vector2(0, -r), br + Vector2(0, r), color, width)
	canvas.draw_line(br + Vector2(r, 0), bl + Vector2(-r, 0), color, width)
	canvas.draw_line(bl + Vector2(0, r), tl + Vector2(0, -r), color, width)

	var points := 8
	_arc(canvas, tl, r, PI, PI * 1.5, points, color, width)
	_arc(canvas, tr, r, PI * 1.5, TAU, points, color, width)
	_arc(canvas, br, r, 0, PI * 0.5, points, color, width)
	_arc(canvas, bl, r, PI * 0.5, PI, points, color, width)


static func draw_dash_line(canvas: CanvasItem, from: Vector2, to: Vector2, dash_len: float, gap_len: float, color: Color, width: float) -> void:
	var total := from.distance_to(to)
	if total <= 0:
		return
	var dir := (to - from).normalized()
	var pos := 0.0
	while pos < total:
		var seg_start := from + dir * pos
		var seg_end: Vector2 = from + dir * minf(pos + dash_len, total)
		canvas.draw_line(seg_start, seg_end, color, width)
		pos += dash_len + gap_len


static func _arc(canvas: CanvasItem, center: Vector2, radius: float, start_angle: float, end_angle: float, points: int, color: Color, width: float) -> void:
	var angle_step := (end_angle - start_angle) / points
	for i in range(points):
		var a1 := start_angle + angle_step * i
		var a2 := start_angle + angle_step * (i + 1)
		var p1 := center + Vector2(cos(a1), sin(a1)) * radius
		var p2 := center + Vector2(cos(a2), sin(a2)) * radius
		canvas.draw_line(p1, p2, color, width)
