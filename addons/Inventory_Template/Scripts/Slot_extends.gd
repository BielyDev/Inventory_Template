extends Control

onready var Void : Node = get_node(void_path)
onready var Equipped_parent := get_node_or_null(equipped_parent_path)
onready var Inventory_parent := get_node("../../../..")

export(bool) var equipped : bool = false
export(Inventory.TYPE) var body : int = 0
export(NodePath) var void_path : NodePath = "../../../../itens_void"
export(NodePath) var equipped_parent_path : NodePath = "../../../../Equipped_Panel/Vbox/Equipped"

var new_item_button : PackedScene = preload("res://addons/Inventory_Template/Scenes/Buttons/Item_button.tscn")
var new_item_no_slot_button : PackedScene = preload("res://addons/Inventory_Template/Scenes/Buttons/Item_no_slot_button.tscn")

var slot_item_id : int = -1 # Item salvo no slot.
var use_type: bool
var instance_itens : Node

func _ready() -> void:
	use_type = body != 0

func set_slot_item() -> void:
	Inventory.slot.item = slot_item_id
	Inventory.slot.node = self


func create_item_void() -> void:
	var my_item = Inventory.search_item(slot_item_id,"",equipped)
	
	if my_item != null and Inventory.save_dat.item_no_slot != null and Inventory.save_dat.item_no_slot.resource_path != my_item.resource_path:
		var save_item = (Inventory.save_dat.item_no_slot)
		
		if equipped:Inventory.save_dat.equipped.erase(my_item)
		else:Inventory.save_dat.inventory.erase(my_item)
		
		Inventory.save_dat.item_no_slot = my_item
		
		get_child(0).queue_free()
		Void.get_child(0).refresh_icon()
		
		var new_item = Inventory.call_add_item(
			save_item.resource_path, 
			save_item.amount,
			save_item.type,
			false,false,get_index(),equipped
		)
		
		slot_item_id = Inventory.search_item(new_item,"",equipped).id
		Inventory.slot = {node = null,item = -1}
		
		add_button(new_item,self,get_index())
		get_child(0).queue_free()
		return
	
	if Inventory.save_dat.item_no_slot == null:
		my_item.amount -= 1
		
		Inventory.save_dat.item_no_slot = {id = my_item.id,
			resource_path = my_item.resource_path,
			type =  my_item.type,
			slot = -1,amount = 1}
		
		var item_button = new_item_no_slot_button.instance()
		Void.add_child(item_button)
		
	else:
		if Inventory.save_dat.item_no_slot.resource_path == my_item.resource_path:
			my_item.amount -= 1
			Inventory.save_dat.item_no_slot.amount += 1
		else:
			Inventory.save_dat.item_no_slot = {id = my_item.id,
				type = my_item.type,
				resource_path = my_item.resource_path,
				slot = -1,amount = 1}
	
	Void.get_child(0).refresh_icon()
	get_child(0).refresh()


var get_gamepad: bool = true
func verific_distance(_event: InputEvent): # Verifica a distancia do mouse ao slot.
	var moupos: Vector2 = Inventory.support.mouse_position
	
	if moupos.distance_to(rect_global_position + rect_size / 2) <= rect_size.x / 2:
		self_modulate.a = 3
		
		if Inventory.support.system_button == Support.SYSTEM_BUTTON.GAMEPAD and get_gamepad:
			Inventory.support.use_cursor = false
			var tw = create_tween()
			
			tw.tween_property(Inventory.support,"cursor_position",rect_global_position + (rect_size / 2),0.05)
			tw.connect("finished",self,"back_cursor_moviment")
			
			get_gamepad = false
		
		return true
	else:
		self_modulate.a = 1
		get_gamepad = true
		return false


func shift_move() -> void:
	var my_item = Inventory.search_item(slot_item_id,"",equipped)
	var verific_item = Inventory.search_item(-1,my_item.resource_path,!equipped)
	
	if verific_item != null:
		verific_item.amount += my_item.amount
		slot_item_id = -1
		
		if equipped: Inventory.save_dat.equipped.erase(my_item)
		else: Inventory.save_dat.inventory.erase(my_item)
		
		Inventory.emit_signal("refresh_itens")
		Inventory.call_equipped_item(use_type)
	else:
		if _create_item_shift(my_item) == false: return
		
		if equipped: Inventory.save_dat.equipped.erase(my_item)
		else: Inventory.save_dat.inventory.erase(my_item)
		slot_item_id = -1
		Inventory.call_equipped_item(use_type)
		Inventory.emit_signal("refresh_itens")


func _create_item_shift(my_item: Dictionary):
	if my_item.type == Inventory.TYPE.null or equipped:
		Inventory.call_add_item(
			my_item.resource_path,
			my_item.amount,
			my_item.type,
			false,
			false,
			null,
			!equipped)
		return true
	else:
		for slots in Equipped_parent.get_children():
			
			if slots.body == my_item.type:
				if slots.slot_item_id != -1: return false
				Inventory.call_add_item(
					my_item.resource_path,
					my_item.amount,
					my_item.type,
					false,
					false,
					slots.get_index(),
					!equipped)
				
				return true
		
		Inventory.call_add_item(
			my_item.resource_path,
			my_item.amount,
			my_item.type,
			false,
			false,
			null,
			!equipped)
		return true


func move_void_item(): #Movimenta um item para um outro slot vazio.
	var inv_slot_item = Inventory.search_item(Inventory.slot.item)
	
	if Inventory.save_dat.item_no_slot != null:
		add_void_button()
		
		return true
	
	if Inventory.slot.item != -1:
		if verific_equipped() == false:
			return false
		
		add_button(Inventory.slot.item,self,get_index())
		
		slot_item_id = Inventory.slot.item
		
		Inventory.slot.node.slot_item_id = -1
		Inventory.slot.node.get_child(0).queue_free()
		
		return true
	
	return false


func transfer_item(): #Movimenta um item para um slot ja preenchido, e faz a troca.
	
	if Inventory.save_dat.item_no_slot != null: #Item que não tem Slot é considerado Item_no_slot
		var my_item =  Inventory.search_item(slot_item_id,"",equipped)
		
		if Inventory.save_dat.item_no_slot.resource_path == my_item.resource_path:
			my_item.amount += 1
			Inventory.save_dat.item_no_slot.amount -= 1
			
			Inventory.emit_signal("refresh_data")
			return true
		else:
			get_child(0).queue_free() # Apaga o item do slot.
			
			# Confere se o item está no equipado ou não.
			if equipped:Inventory.save_dat.equipped.erase(my_item)
			else:Inventory.save_dat.inventory.erase(my_item)
			
			var save_item = (Inventory.save_dat.item_no_slot)
			var new_item = Inventory.call_add_item(
					save_item.resource_path, 
					save_item.amount,
					save_item.type,
					false,false,get_index(),equipped)
			
			Inventory.save_dat.item_no_slot = my_item
			
			Void.get_child(0).refresh_icon() # Atualiza o icone do item sem slot.
			
			slot_item_id = Inventory.search_item(new_item,"",equipped).id
			
			return true
		
		var new_item = Inventory.call_add_item(
			Inventory.save_dat.item_no_slot.resource_path,
			Inventory.save_dat.item_no_slot.amount,
			Inventory.save_dat.item_no_slot.type,
			false,false,null,equipped)
		
		Void.get_child(0).queue_free()
		add_button(new_item,self,get_index())
		
		slot_item_id = new_item
		
		Inventory.save_dat.item_no_slot = null
		Inventory.slot = {node = null,item = -1}
		return true
	
	if is_instance_valid(Inventory.slot.node): # Soma com o que tem
		if Inventory.slot.node != self:
			var my_item =  Inventory.search_item(slot_item_id,"",equipped)
			var other_item = Inventory.search_item(Inventory.slot.item,"",equipped)
			
			if other_item == null:
				other_item = Inventory.search_item(Inventory.slot.item,"",!equipped)
			
			if other_item.resource_path == my_item.resource_path:
				my_item.amount += other_item.amount
				other_item.amount = 0
				Inventory.slot = {node = null,item = -1}
				
				yield(get_tree().create_timer(0.05),"timeout")
				Inventory.emit_signal("refresh_itens")
				
				return false
			else:
				if verific_equipped(false) == false:
					Inventory.slot = {node = null,item = -1}
					return false
				
				Inventory.slot.node.get_child(0).queue_free()
				get_child(0).queue_free()
				
				add_button(slot_item_id,Inventory.slot.node,other_item.slot)
				Inventory.slot.node.add_button(Inventory.slot.item,self,get_index())
				
				transfer_inv_equip(my_item,other_item)
				
				Inventory.slot.node.slot_item_id = slot_item_id
				slot_item_id = Inventory.slot.item
				Inventory.slot = {node = null,item = -1}
				Inventory.emit_signal("refresh_itens")
				return true
		
		else:# Voltou pro mesmo slot
			Inventory.slot = {node = null,item = -1}
			return false


func verific_equipped(refresh: bool = true):
	
	var my_item = Inventory.search_item(slot_item_id,"",equipped)
	var verific_item = Inventory.search_item(Inventory.slot.item,"",!equipped)
	var verific_item_equip = Inventory.search_item(Inventory.slot.item,"",equipped)
	var inventory_true = Inventory.search_item(Inventory.slot.item,"",true)
	var inventory_false = Inventory.search_item(Inventory.slot.item)
	
	if equipped == true:
		if verific_item != null:
			if body != 0:
				if verific_item.type != body:
					return false
		
		else:
			if verific_item_equip != null:
				if body != 0 and verific_item_equip.type != body:
					return false
		
		if inventory_true:
			return true
		
		if refresh:
			Inventory.save_dat.equipped.append(verific_item)
			Inventory.save_dat.inventory.erase(verific_item)
	
	else:
		if inventory_true != null and my_item != null:
			if Inventory.slot.node.body != 0:
				if inventory_true.type != my_item.type:
					return false
		
		if inventory_false:
			return true
		
		if refresh:
			Inventory.save_dat.inventory.append(verific_item)
			Inventory.save_dat.equipped.erase(verific_item)


func transfer_inv_equip(my_item,other_item) -> void:
	if equipped != Inventory.slot.node.equipped:
		if equipped:
			Inventory.save_dat.inventory.append(my_item)
			Inventory.save_dat.equipped.append(other_item)
			
			Inventory.save_dat.equipped.erase(my_item)
			Inventory.save_dat.inventory.erase(other_item)
		else:
			Inventory.save_dat.equipped.append(my_item)
			Inventory.save_dat.inventory.append(other_item)
			
			Inventory.save_dat.inventory.erase(my_item)
			Inventory.save_dat.equipped.erase(other_item)


func add_void_button() -> void: # Adiciona o item do item_no_slot a um slot.
	var new_item = Inventory.call_add_item(
		Inventory.save_dat.item_no_slot.resource_path,
		Inventory.save_dat.item_no_slot.amount,
		Inventory.save_dat.item_no_slot.type,
		false,false,get_index(),equipped)
	slot_item_id = new_item
	
	Inventory.save_dat.item_no_slot = null


func add_button(item_save: int,slot,index: int) -> void: # Cria o botão do item especificado.
	var item_search = Inventory.search_item(item_save,"",equipped)
	var item_button = new_item_button.instance()
	item_button.item = item_search
	item_search.slot = index
	slot.add_child(item_button)


func back_cursor_moviment() -> void:
	yield(get_tree().create_timer(0.1),"timeout")
	Inventory.support.use_cursor = true

