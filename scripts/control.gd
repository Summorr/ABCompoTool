extends Control

var png_path : String = "res://icon.svg"
var xml_path : String = ""
var com_path : String = ""
var sprites : Array = []
var group : Array = []
var compos : Array = []
@export var svs : Node

func _ready() -> void:
	if "zh" in TranslationServer.get_locale():
		$settings/Panel/LangOption.selected = 0
	else:
		$settings/Panel/LangOption.selected = 1
func _process(delta: float) -> void:
	$compo.position = get_local_mouse_position()
	if Input.is_action_just_pressed("q"):
		$compo.scale += Vector2(0.1,0.1)
	if Input.is_action_just_pressed("e"):
		$compo.scale -= Vector2(0.1,0.1)
	
	
func _on_inimg_pressed() -> void:
	$imgsel.show()

func _on_inxml_pressed() -> void:
	$xmlsel.show()

func png_selected(path: String) -> void:
	png_path = path
	$ui/sprite.texture = ImageTexture.create_from_image(Image.load_from_file(path))
	print(path)


func xml_selected(path: String) -> void:
	$ui/sprlst.clear()
	xml_path = path
	sprites = analy_xml(path)
	for i in sprites:
		$ui/sprlst.add_item(i["name"])

func _on_sprlst_spr_selected(index: int) -> void:
	var region = AtlasTexture.new()
	region.atlas = ImageTexture.create_from_image(Image.load_from_file(png_path))
	region.region = Rect2(sprites[index]["x"], sprites[index]["y"], sprites[index]["width"], sprites[index]["height"])
	$ui/sprite.texture = region

# XML解析函数
func analy_xml(path: String) -> Array:
	var sprite_list = []
	var parser = XMLParser.new()

	if parser.open(path) != OK:
		return sprite_list

	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT && parser.get_node_name() == "sprite":
			# 正确用法：遍历所有属性，用索引获取
			var attrs = {}
			var count = parser.get_attribute_count()
			for i in range(count):
				var key = parser.get_attribute_name(i)
				var value = parser.get_attribute_value(i)
				attrs[key] = value

			# 安全取值
			var data = {
				"name": attrs.get("name", ""),
				"x": attrs.get("x", "0").to_int(),
				"y": attrs.get("y", "0").to_int(),
				"width": attrs.get("width", "0").to_int(),
				"height": attrs.get("height", "0").to_int(),
				"pivotX": attrs.get("pivotX", "0").to_int(),
				"pivotY": attrs.get("pivotY", "0").to_int()
			}
			sprite_list.append(data)

	return sprite_list

# 解析composprite的XML
func analy_com(path: String) -> Array:
	var parser = XMLParser.new()
	var all_compos: Array = []
	var current_compo: Dictionary = {}
	var current_layers: Array = []

	if parser.open(path) != OK:
		return all_compos

	while parser.read() == OK:
		var type = parser.get_node_type()

		if type == XMLParser.NODE_ELEMENT and parser.get_node_name() == "composprite":
			var name = parser.get_named_attribute_value_safe("name")
			current_compo = { "name": name, "layers": [] }
			current_layers = current_compo["layers"]

		elif type == XMLParser.NODE_ELEMENT and parser.get_node_name() == "layer":
			var sprite = parser.get_named_attribute_value_safe("sprite")
			var x = parser.get_named_attribute_value_safe("x").to_int()
			var y = parser.get_named_attribute_value_safe("y").to_int()
			current_layers.append({
				"sprite": sprite,
				"x": x,
				"y": y
			})

		elif type == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == "composprite":
			all_compos.append(current_compo)
			current_compo = { "name": "", "layers": [] }
	return all_compos

func _on_add_2_group_pressed() -> void:
	for i in range($ui/sprlst.item_count):
		var region = AtlasTexture.new()
		region.atlas = ImageTexture.create_from_image(Image.load_from_file(png_path))
		region.region = Rect2(sprites[i]["x"], sprites[i]["y"], sprites[i]["width"], sprites[i]["height"])
		$ui/sprite.texture = region
		group.append({"name":sprites[i]["name"],"region":region})
		$ui/grouplst.add_item(sprites[i]["name"])


func _on_grouplst_item_selected(index: int) -> void:
	$ui/sprite.texture = group[index]["region"]


func _on_incom_pressed() -> void:
	$comsel.show()


func _on_comsel_file_selected(path: String) -> void:
	com_path = path
	compos = analy_com(path)
	for i in compos:
		$ui/comlst.add_item(i["name"])


func _on_comlst_com_selected(index: int) -> void:
	if $compo.get_children() != []:
		for i in $compo.get_children():
			i.queue_free()
	print(compos[index]["layers"])
	print(compos[index]["layers"].size())
	$ui/analy.text = ""
	for i in compos[index]["layers"]:
		var spr = Sprite2D.new()
		spr.texture = load("res://icon.svg")
		spr.position.x = i["x"]
		spr.position.y = i["y"]
		var flag = false
		for j in group:
			if j.find_key(i["sprite"]) != null:
				spr.texture = j["region"]
				flag = true
			else:
				print(j)
		if not flag:
			$ui/analy.text += "[color=red]Missing Texture:"+str(i["sprite"])+"[/color]\n"
		$compo.add_child(spr)
		
func _on_exportcom_pressed() -> void:
	export_compo_to_png()
func get_compo_total_rect() -> Rect2:
	var compo = $compo
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	var has_sprite = false

	for child in compo.get_children():
		if child is Sprite2D and child.visible and child.texture:
			has_sprite = true
			var rect = child.get_rect()
			var world_pos = child.position + rect.position
			min_x = min(min_x, world_pos.x)
			min_y = min(min_y, world_pos.y)
			max_x = max(max_x, world_pos.x + rect.size.x)
			max_y = max(max_y, world_pos.y + rect.size.y)

	if not has_sprite:
		return Rect2()
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

func get_compo_size() -> Vector2:
	var r = get_compo_total_rect()
	if r.size == Vector2.ZERO:
		return Vector2.ZERO
	return r.size + Vector2(2, 2)

func export_compo_to_png():
	$savecom.popup_centered()
	var path = await $savecom.file_selected
	if path.is_empty():
		return
	var total_rect = get_compo_total_rect()
	var size = get_compo_size().round()

	if size == Vector2.ZERO:
		return

	var copy_compo = $compo.duplicate()
	copy_compo.name = "comspr"
	copy_compo.scale = Vector2(1,1)

	copy_compo.position = -total_rect.position + Vector2(1, 1)

	var sv = $SubViewportContainer/SubViewport
	sv.size = size
	sv.transparent_bg = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	sv.add_child(copy_compo)

	await get_tree().process_frame
	await get_tree().process_frame

	var img = sv.get_texture().get_image()
	img.save_png(path)

	copy_compo.queue_free()
	$ui/analy.text = "Exported Successfully:"+path


func _on_lang_option_item_selected(index: int) -> void:
	if index == 0:
		TranslationServer.set_locale("zh")
	if index == 1:
		TranslationServer.set_locale("en")


func _on_xset_pressed() -> void:
	$settings.hide()

func _on_settings_pressed() -> void:
	$settings.show()
