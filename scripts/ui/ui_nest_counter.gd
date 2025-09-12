extends Control

## UiNestCounter - shows how many nests were fed in the current session

@export var nest_amount_label_path: NodePath

var _label: Label

func _ready():
	_resolve_nodes()
	_refresh_from_stats()

	if GameStats:
		if not GameStats.stats_updated.is_connected(_on_stats_updated):
			GameStats.stats_updated.connect(_on_stats_updated)
		if not GameStats.session_reset.is_connected(_on_session_reset):
			GameStats.session_reset.connect(_on_session_reset)

func _exit_tree():
	if GameStats:
		if GameStats.stats_updated.is_connected(_on_stats_updated):
			GameStats.stats_updated.disconnect(_on_stats_updated)
		if GameStats.session_reset.is_connected(_on_session_reset):
			GameStats.session_reset.disconnect(_on_session_reset)

func _resolve_nodes():
	if nest_amount_label_path != NodePath(""):
		_label = get_node_or_null(nest_amount_label_path)
	if _label == null:
		# fallback: try find by name in children
		_label = find_child("NestAmountLabel", true, false)

func _refresh_from_stats():
	var value := 0
	if GameStats and GameStats.has_method("get_fed_nests_count"):
		value = GameStats.get_fed_nests_count()
	_set_count(value)

func _on_stats_updated(fed_nests: int):
	_set_count(fed_nests)

func _on_session_reset():
	_set_count(0)

func _set_count(amount: int):
	if _label:
		_label.text = str(amount)


