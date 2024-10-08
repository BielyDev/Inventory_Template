extends Control

onready var Itens_void : Node = $"../itens_void"


func _input(_event: InputEvent) -> void:
	if _event is InputEventMouseMotion:
		verific_distance()
	if _event is InputEventMouseButton:
		if verific_distance():
			discart()


func discart() -> void:
	if is_instance_valid(Inventory.slot.node):
		if Inventory.slot.node.equipped:
			var item = Inventory.search_item(Inventory.slot.item,"",true)
			
			Inventory.emit_signal("discart_item",item)
			Inventory.save_dat.equipped.erase(item)
			
			Inventory.slot.node.get_child(0).queue_free()
			Inventory.slot = {node = null,item = -1}
		else:
			var item = Inventory.search_item(Inventory.slot.item)
			
			Inventory.emit_signal("discart_item",item)
			Inventory.save_dat.inventory.erase(item)
			
			Inventory.slot.node.get_child(0).queue_free()
			Inventory.slot = {node = null,item = -1}
	
	item_void_queue()


func item_void_queue() -> void:
	if Inventory.save_dat.item_no_slot != null:
		Itens_void.get_child(0).queue_free()
		Inventory.save_dat.item_no_slot = null


func verific_distance(): # Verifica a distancia.
	if Inventory.support.mouse_position.distance_to(rect_global_position+rect_size/2) <= rect_size.x/2:
		self_modulate = Color.red
		return true
	else:
		self_modulate = Color.white
		return false

