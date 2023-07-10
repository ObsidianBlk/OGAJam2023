@tool
extends Trigger
class_name TriggerBinOp


# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
enum BINOP {And=0, Or=1, Xor=2, Nand=3, Nor=4}

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Binary Operation Trigger")
@export var binary_operation : BINOP = BINOP.And
@export var inputs : Array[Trigger] = []

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _input_states : Dictionary = {}

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_inputs(ip : Array[Trigger]) -> void:
	inputs = ip
	_UpdateInputConnections()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateInputConnections()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateInputConnections() -> void:
	if Engine.is_editor_hint(): return
	var active : Dictionary = {}
	for idx in range(inputs.size()):
		# Store the trigger name in a dictionary for the second pass...
		if not inputs[idx].name in active:
			active[inputs[idx].name] = inputs[idx].name
		
		# If this trigger isn't already in the _input_states dictionary, put it there
		if not inputs[idx].name in _input_states:
			_input_states[inputs[idx].name] = {
				"activated": inputs[idx].is_activated(),
				"node": weakref(inputs[idx])
			}
		
		# Connect the signals if not already set.
		if not inputs[idx].activated.is_connected(_on_trigger_activated.bind(inputs[idx])):
			inputs[idx].activated.connect(_on_trigger_activated.bind(inputs[idx]))
		if not inputs[idx].deactivated.is_connected(_on_trigger_deactivated.bind(inputs[idx])):
			inputs[idx].deactivated.connect(_on_trigger_deactivated.bind(inputs[idx]))
	
	# Disconnect any connections not currently in the given inputs array!
	var keys : Array = _input_states.keys()
	for key in keys:
		# Get the trigger object
		var input : Trigger = _input_states[key].node.get_ref()
		# If the trigger doesn't exist, or the key isn't in the active dictionary...
		if input == null or not key in active:
			if input != null: # Clear all signal connections if the trigger does exist.
				if input.activated.is_connected(_on_trigger_activated.bind(input)):
					input.activated.disconnect(_on_trigger_activated.bind(input))
				if not input.deactivated.is_connected(_on_trigger_deactivated.bind(input)):
					input.deactivated.disconnect(_on_trigger_deactivated.bind(input))
			# Remove the entry from the dictionary.
			_input_states.erase(key)

func _CheckActiveState() -> void:
	var state : Variant = null
	match binary_operation:
		BINOP.And, BINOP.Nand:
			state = _CheckAnd(binary_operation == BINOP.Nand)
		BINOP.Or, BINOP.Nor:
			state = _CheckOr(binary_operation == BINOP.Nor)
		BINOP.Xor:
			state = _CheckXor()
	
	if typeof(state) == TYPE_BOOL:
		if state != _activated:
			_activated = state
			if _activated:
				activated.emit()
			else:
				deactivated.emit()

func _CheckAnd(negate : bool) -> bool:
	for key in _input_states:
		var info : Dictionary = _input_states[key]
		if info.node.get_ref() == null:
			continue
		if info.activated == false:
			return true if negate else false
	return false if negate else true

func _CheckOr(negate : bool) -> bool:
	for key in _input_states:
		var info : Dictionary = _input_states[key]
		if info.node.get_ref() == null:
			continue
		if info.activated == true:
			return false if negate else true
	return true if negate else false

func _CheckXor() -> bool:
	var found_one = false
	for key in _input_states:
		var info : Dictionary = _input_states[key]
		if info.node.get_ref() == null:
			continue
		if info.activated == true:
			if found_one == true:
				return false
			found_one = true
	return found_one

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_activated(a : bool) -> void:
	if inputs.size() <= 0:
		super.set_activated(a)
	else:
		printerr("Trigger effected by inputs. Cannot set trigger active state.")

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_trigger_activated(t : Trigger) -> void:
	if t.name in _input_states:
		_input_states[t.name].activated = true
		_CheckActiveState.call_deferred()

func _on_trigger_deactivated(t : Trigger) -> void:
	if t.name in _input_states:
		_input_states[t.name].activated = false
		_CheckActiveState.call_deferred()
