class_name DemolishCommand
extends SimulationCommand

var _cell: Vector2i


func _init(cell: Vector2i) -> void:
	_cell = cell


func execute(state: EconomyState, params: Params, _rng: RandomNumberGenerator) -> void:
	accepted = false
	reason = &"no_building"
	for index: int in range(state.buildings.size()):
		if state.buildings[index]["cell"] == [_cell.x, _cell.y]:
			var refund: int = _refund(state, params, state.buildings[index])
			state.money += refund
			# Net spending keeps the panel's construction line honest.
			state.construction_spent_tick -= refund
			# Work in progress belongs to the building; global stocks survive demolition.
			state.buildings.remove_at(index)
			accepted = true
			reason = &""
			return


func _refund(state: EconomyState, params: Params, building: Dictionary) -> int:
	var cost: int = int(params.get_value(StringName("building.%s.cost" % building["definition_id"])))
	if _in_grace(state, params, building):
		return cost
	return roundi(cost * float(params.get_value(&"demolish.refund_ratio")))


# Fresh or idle buildings are an undo, not a sale. A missing build time counts as established.
func _in_grace(state: EconomyState, params: Params, building: Dictionary) -> bool:
	if int(building.get("workers", 0)) == 0:
		return true
	if not building.has("built_at"):
		return false
	var age: int = state.defeat_elapsed_seconds - int(building["built_at"])
	return age <= float(params.get_value(&"demolish.refund_grace_seconds"))
