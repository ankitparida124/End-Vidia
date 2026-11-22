extends CanvasLayer

# NVIDIA stock ticker: every GPU the runner grabs pushes NVDA up.
const START_PRICE = 140.0
const GPU_GAIN = 0.03
const KNOCKOUT_GAIN = 0.01
const FALL_LOSS = 0.04
const HISTORY_SIZE = 40

@onready var price_label: Label = %PriceLabel
@onready var change_label: Label = %ChangeLabel
@onready var arrow_shape: Polygon2D = %ArrowShape
@onready var gpu_label: Label = %GPULabel
@onready var chart: Line2D = %Chart
@onready var chart_area: Control = %ChartArea
@onready var message_label: Label = %MessageLabel
@onready var popup_label: Label = %PopupLabel

var price = START_PRICE
var shown_price = START_PRICE
var history: Array[float] = []


func _ready() -> void:
	for i in HISTORY_SIZE:
		history.append(START_PRICE)
	update_ticker()
	show_message("GO!", 1.2)


func _process(delta: float) -> void:
	if not is_equal_approx(shown_price, price):
		shown_price = move_toward(shown_price, price, max(abs(price - shown_price), 1.0) * 4 * delta)
		update_ticker()


func on_gpus_changed(total: int) -> void:
	gpu_label.text = "GPUs: %d" % total
	change_price(price * GPU_GAIN)
	popup("+1 GPU · NVDA UP!")


func on_enemy_knocked_out() -> void:
	change_price(price * KNOCKOUT_GAIN)
	popup("KNOCKOUT!")


func on_fell() -> void:
	change_price(-price * FALL_LOSS)
	popup("OOPS! NVDA DOWN")


func on_finished() -> void:
	show_message("QUALIFIED!\nNVDA $%.2f" % price, 0.0)


func change_price(amount: float) -> void:
	price = max(price + amount, 1.0)
	history.append(price)
	history.pop_front()


func update_ticker() -> void:
	var change = shown_price - START_PRICE
	var up = change >= 0
	var color = Color(0.46, 0.85, 0.0) if up else Color(1, 0.3, 0.3)
	price_label.text = "$%.2f" % shown_price
	change_label.text = "%s%.2f (%s%.2f%%)" % ["+" if up else "", change, "+" if up else "", change / START_PRICE * 100]
	change_label.modulate = color
	arrow_shape.scale.y = 1 if up else -1
	arrow_shape.color = color
	chart.default_color = color

	var low = history.min()
	var high = max(history.max(), low + 1.0)
	var size = chart_area.size
	var points = PackedVector2Array()
	for i in history.size():
		points.append(Vector2(size.x * i / (history.size() - 1), size.y - (history[i] - low) / (high - low) * size.y))
	chart.points = points


func popup(text: String) -> void:
	popup_label.text = text
	popup_label.modulate.a = 1.0
	popup_label.pivot_offset = popup_label.size / 2
	popup_label.scale = Vector2(1.4, 1.4)
	var tween = create_tween().set_parallel()
	tween.tween_property(popup_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tween.tween_property(popup_label, "modulate:a", 0.0, 0.6).set_delay(0.7)


func show_message(text: String, duration: float) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	message_label.pivot_offset = message_label.size / 2
	message_label.scale = Vector2(0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(message_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	if duration > 0.0:
		tween.tween_property(message_label, "modulate:a", 0.0, 0.4).set_delay(duration)
