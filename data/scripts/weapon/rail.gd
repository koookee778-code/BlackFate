extends Spatial

var speed : float = 200;
export(NodePath) var timer;
var target = null setget set_target

func set_target(val):
	target = val
	if val is Vector3:
		if global_transform.origin.distance_squared_to(val) > 0.1:
			look_at(val, Vector3.UP)

func _ready() -> void:
	if has_node("mesh"):
		$mesh.translation.z = -$mesh.mesh.mid_height / 2.0;
	if has_node("timer"):
		var t = get_node("timer")
		t.connect("timeout", self, "queue_free")
	elif timer:
		var t = get_node_or_null(timer)
		if t:
			t.connect("timeout", self, "queue_free")

func _process(_delta) -> void:
	translation -= (global_transform.basis.z * speed) * _delta;
