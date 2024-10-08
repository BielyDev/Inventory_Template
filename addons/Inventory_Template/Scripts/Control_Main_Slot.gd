extends Control

export(int,"inventory","equip") var Mode

var new_item_button : PackedScene = preload("res://addons/Inventory_Template/Scenes/Buttons/Item_button.tscn")
var item_button
var timer_reset: Timer = Timer.new()


func _ready() -> void:
	Inventory.connect("refresh_itens",self,"refresh")
	Inventory.connect("item_data",self,"add_item")
	
	refresh()

func _input(_event: InputEvent) -> void:
	if _event is InputEventMouseMotion:
		if Inventory.save_dat.item_no_slot == null:
			item_moviment()


func item_moviment() -> void: # Movimentar o item com o mouse.
	if is_instance_valid(Inventory.slot.node) and Inventory.slot.node.get_children().size() >= 1:
		item_button = Inventory.slot.node
		
		item_button.get_child(0).rect_global_position = Inventory.support.mouse_position-item_button.rect_size/2
		item_button.get_child(0).get_child(0).z_index = 1
	
	if item_button != Inventory.slot.node:
		if is_instance_valid(item_button) and item_button.get_child_count() >= 1:
			item_button.get_child(0).get_child(0).z_index = 0
			item_button.get_child(0).rect_position = Vector2(10,10)
			
			Inventory.slot = {node = null,item = -1}


func refresh() -> void: # Apaga todos os itens da interface e adiciona novamente.
	for child in get_children(): #Apaga todos os itens_buttons dos slots.
		for childs in child.get_children():
			childs.queue_free()
	
	if Mode == 0:
		for itens in Inventory.save_dat.inventory: #Adiciona no inventario.
			create_buttons(itens)
	if Mode == 1:
		for itens in Inventory.save_dat.equipped: #Adiciona nos equipados.
			create_buttons(itens)


func add_item(item: Dictionary) -> void:
	
	var search_item = Inventory.search_item(item.id,"",Mode)
	
	if search_item != null:
		create_buttons(item)


func create_buttons(itens) -> void:
	var item_button_ = new_item_button.instance()
	item_button_.item = itens
	
	if itens.slot != -1:
		get_child(itens.slot).slot_item_id = itens.id
		get_child(itens.slot).add_child(item_button_)

