extends Control

const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const POKEAPI_URL := "https://pokeapi.co/api/v2/pokemon-species?limit=2000"
const SPRITE_URL := "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/%d.png"
const BUILD_INFO = preload("res://build_info.gd")

var letter_index := 0
var rounds_completed := 0
var answers: Array[String] = []
var used_names: Dictionary = {}
var pokemon_names: Dictionary = {}
var validation_ready := false
var run_over := false

var recent_rows: Array[HBoxContainer] = []
var letter_label: Label
var recent_list: VBoxContainer
var entry: LineEdit
var status_label: Label
var progress_label: Label
var answers_scroll: ScrollContainer
var answers_grid: GridContainer
var suggestions_scroll: ScrollContainer
var suggestions_label: Label
var stumped_button: Button
var restart_button: Button


func _ready() -> void:
	_build_ui()
	get_viewport().size_changed.connect(_update_grid_columns)
	_update_grid_columns()
	_update_screen()
	_load_pokemon_names()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#09142d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var build_label := Label.new()
	build_label.text = BUILD_INFO.LABEL
	build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	build_label.add_theme_font_size_override("font_size", 12)
	build_label.add_theme_color_override("font_color", Color("#8290ad"))
	build_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	build_label.position = Vector2(-150, 8)
	build_label.size = Vector2(138, 22)
	add_child(build_label)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 7)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "POKÉMON ALPHABET CHALLENGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#ffcb05"))
	layout.add_child(title)

	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 16)
	layout.add_child(progress_label)

	var current_row := HBoxContainer.new()
	current_row.custom_minimum_size = Vector2(0, 92)
	current_row.add_theme_constant_override("separation", 12)
	layout.add_child(current_row)

	letter_label = Label.new()
	letter_label.custom_minimum_size = Vector2(72, 86)
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter_label.add_theme_font_size_override("font_size", 48)
	letter_label.add_theme_color_override("font_color", Color("#62a8e5"))
	current_row.add_child(letter_label)

	recent_list = VBoxContainer.new()
	recent_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recent_list.add_theme_constant_override("separation", 1)
	current_row.add_child(recent_list)

	answers_scroll = ScrollContainer.new()
	answers_scroll.custom_minimum_size = Vector2(0, 86)
	answers_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	answers_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	answers_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	layout.add_child(answers_scroll)

	answers_grid = GridContainer.new()
	answers_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answers_grid.add_theme_constant_override("h_separation", 5)
	answers_grid.add_theme_constant_override("v_separation", 5)
	answers_scroll.add_child(answers_grid)

	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	layout.add_child(input_row)

	entry = LineEdit.new()
	entry.placeholder_text = "Name a Pokémon..."
	entry.custom_minimum_size = Vector2(0, 50)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_theme_font_size_override("font_size", 20)
	entry.keep_editing_on_text_submit = true
	entry.text_submitted.connect(_submit_answer)
	entry.gui_input.connect(_on_entry_gui_input)
	input_row.add_child(entry)

	stumped_button = Button.new()
	stumped_button.text = "Give Up 😔"
	stumped_button.focus_mode = Control.FOCUS_NONE
	stumped_button.add_theme_color_override("font_color", Color.WHITE)
	stumped_button.add_theme_font_size_override("font_size", 16)
	var give_up_style := StyleBoxFlat.new()
	give_up_style.bg_color = Color("#b83a4b")
	give_up_style.corner_radius_top_left = 8
	give_up_style.corner_radius_top_right = 8
	give_up_style.corner_radius_bottom_left = 8
	give_up_style.corner_radius_bottom_right = 8
	give_up_style.content_margin_top = 10
	give_up_style.content_margin_bottom = 10
	stumped_button.add_theme_stylebox_override("normal", give_up_style)
	stumped_button.pressed.connect(_stumped)
	layout.add_child(stumped_button)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 22)
	status_label.visible = false
	layout.add_child(status_label)

	suggestions_scroll = ScrollContainer.new()
	suggestions_scroll.visible = false
	suggestions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	suggestions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(suggestions_scroll)

	suggestions_label = Label.new()
	suggestions_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suggestions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	suggestions_label.add_theme_font_size_override("font_size", 15)
	suggestions_scroll.add_child(suggestions_label)

	# Keep controls above content that the phone keyboard may cover.
	layout.move_child(input_row, 2)
	layout.move_child(stumped_button, 3)
	layout.move_child(status_label, 4)

	restart_button = Button.new()
	restart_button.text = "Play Again"
	restart_button.visible = false
	restart_button.pressed.connect(_restart)
	layout.add_child(restart_button)


func _update_grid_columns() -> void:
	if not is_instance_valid(answers_grid):
		return
	var available_width := get_viewport_rect().size.x - 32.0
	answers_grid.columns = clampi(int(available_width / 68.0), 3, 7)


func _on_entry_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_open_keyboard()


func _open_keyboard() -> void:
	entry.grab_focus()
	entry.edit()
	DisplayServer.virtual_keyboard_show(
		entry.text,
		entry.get_global_rect(),
		DisplayServer.KEYBOARD_TYPE_DEFAULT,
		-1,
		entry.caret_column
	)


func _load_pokemon_names() -> void:
	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_pokemon_list_loaded.bind(request))
	if request.request(POKEAPI_URL) != OK:
		status_label.text = "Offline mode — starting-letter checks only."
		status_label.visible = true


func _on_pokemon_list_loaded(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	request: HTTPRequest
) -> void:
	request.queue_free()
	if response_code != 200:
		status_label.text = "Offline mode — starting-letter checks only."
		status_label.visible = true
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY or not data.has("results"):
		status_label.text = "Offline mode — starting-letter checks only."
		status_label.visible = true
		return

	for item in data.results:
		var name := String(item.name).to_lower()
		var url := String(item.url).trim_suffix("/")
		pokemon_names[name] = int(url.get_file())
	validation_ready = true
	status_label.visible = false
	_skip_unavailable_letters()
	_update_screen()


func _submit_answer(raw_answer: String) -> void:
	if run_over:
		return

	var answer := raw_answer.strip_edges()
	if answer.is_empty():
		_show_error("Enter a Pokémon name.")
		return

	var expected := LETTERS[letter_index]
	if answer.left(1).to_upper() != expected:
		_show_error("That name must begin with %s." % expected)
		return

	var accepted_answer := answer
	var api_name := _normalize_name(answer)
	if validation_ready:
		api_name = _find_pokemon_match(answer, expected)
		if api_name.is_empty():
			_show_error("That Pokémon isn't in the Pokédex.")
			return
		accepted_answer = _pretty_name(api_name)

	if used_names.has(api_name):
		_show_error("You already used that Pokémon.")
		return

	used_names[api_name] = true
	answers.append(accepted_answer)
	_add_answer_card(accepted_answer, api_name)
	letter_index += 1
	entry.clear()
	status_label.visible = false

	if letter_index >= LETTERS.length():
		rounds_completed += 1
		letter_index = 0
	_skip_unavailable_letters()
	_update_screen()
	entry.grab_focus()
	entry.edit()
	call_deferred("_scroll_to_latest")


func _skip_unavailable_letters() -> void:
	if not validation_ready or run_over:
		return
	var checked := 0
	while checked < LETTERS.length() and _available_names_for_letter(LETTERS[letter_index]).is_empty():
		letter_index += 1
		checked += 1
		if letter_index >= LETTERS.length():
			rounds_completed += 1
			letter_index = 0
	if checked >= LETTERS.length():
		_end_run("You used every available Pokémon!")


func _available_names_for_letter(letter: String) -> Array[String]:
	var available: Array[String] = []
	for candidate: String in pokemon_names:
		if candidate.left(1).to_upper() == letter and not used_names.has(candidate):
			available.append(candidate)
	available.sort()
	return available


func _add_answer_card(display_name: String, api_name: String) -> void:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(52, 52)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	answers_grid.add_child(card)

	var compact_sprite := TextureRect.new()
	compact_sprite.custom_minimum_size = Vector2(48, 48)
	compact_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	compact_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	compact_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.add_child(compact_sprite)

	var recent_row := HBoxContainer.new()
	recent_row.custom_minimum_size = Vector2(0, 28)
	recent_list.add_child(recent_row)
	recent_rows.append(recent_row)

	var recent_sprite := TextureRect.new()
	recent_sprite.custom_minimum_size = Vector2(28, 28)
	recent_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	recent_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	recent_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	recent_row.add_child(recent_sprite)

	var name_label := Label.new()
	name_label.text = display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 13)
	recent_row.add_child(name_label)

	while recent_rows.size() > 3:
		var oldest := recent_rows.pop_front()
		oldest.queue_free()

	_load_sprite(api_name, compact_sprite, true)
	_load_sprite(api_name, recent_sprite, false)


func _load_sprite(api_name: String, target: TextureRect, animate: bool) -> void:
	if not pokemon_names.has(api_name):
		return
	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_sprite_loaded.bind(request, target, animate))
	request.request(SPRITE_URL % int(pokemon_names[api_name]))


func _on_sprite_loaded(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
		request: HTTPRequest,
	target: TextureRect,
	animate: bool
) -> void:
	request.queue_free()
	if response_code != 200 or not is_instance_valid(target):
		return
	var image := Image.new()
	if image.load_png_from_buffer(body) != OK:
		return
	var texture := ImageTexture.create_from_image(image)
	target.texture = texture
	if animate:
		_animate_sprite(texture, target)


func _animate_sprite(texture: Texture2D, target: TextureRect) -> void:
	await get_tree().process_frame
	if not is_instance_valid(target):
		return
	target.modulate.a = 0.0
	var flying := TextureRect.new()
	flying.texture = texture
	flying.custom_minimum_size = Vector2(58, 58)
	flying.size = Vector2(58, 58)
	flying.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flying.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flying.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(flying)

	var start := letter_label.global_position + letter_label.size * 0.5 - flying.size * 0.5
	var destination := target.global_position + target.size * 0.5 - flying.size * 0.5
	flying.global_position = start
	flying.scale = Vector2(1.35, 1.35)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flying, "global_position", destination, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(flying, "scale", Vector2.ONE, 0.38)
	tween.set_parallel(false)
	tween.tween_callback(_finish_sprite_flight.bind(flying, target))


func _finish_sprite_flight(flying: TextureRect, target: TextureRect) -> void:
	var burst_position := flying.global_position + flying.size * 0.5
	if is_instance_valid(target):
		target.modulate.a = 1.0
	flying.queue_free()
	_emit_particles(burst_position)


func _emit_particles(center: Vector2) -> void:
	var colors := [Color("#ffcb05"), Color("#62a8e5"), Color("#ff6b6b")]
	for index in range(8):
		var particle := ColorRect.new()
		particle.color = colors[index % colors.size()]
		particle.size = Vector2(6, 6)
		particle.global_position = center - particle.size * 0.5
		add_child(particle)
		var angle := TAU * float(index) / 8.0
		var destination := particle.position + Vector2.from_angle(angle) * 34.0
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", destination, 0.32)
		tween.tween_property(particle, "modulate:a", 0.0, 0.32)
		tween.set_parallel(false)
		tween.tween_callback(particle.queue_free)


func _scroll_to_latest() -> void:
	await get_tree().process_frame
	answers_scroll.scroll_vertical = int(answers_scroll.get_v_scroll_bar().max_value)


func _normalize_name(value: String) -> String:
	return value.to_lower().replace("♀", "-f").replace("♂", "-m").replace(" ", "-").replace(".", "").replace("'", "")


func _find_pokemon_match(answer: String, expected_letter: String) -> String:
	var normalized := _normalize_name(answer)
	if pokemon_names.has(normalized):
		return normalized

	var best_match := ""
	var best_distance := 999
	for candidate: String in pokemon_names:
		if candidate.left(1).to_upper() != expected_letter or used_names.has(candidate):
			continue
		var distance := _edit_distance(normalized, candidate)
		if distance < best_distance:
			best_distance = distance
			best_match = candidate

	var allowed_distance := 1 if normalized.length() <= 6 else 2
	return best_match if best_distance <= allowed_distance else ""


func _edit_distance(left: String, right: String) -> int:
	var previous: Array[int] = []
	for column in range(right.length() + 1):
		previous.append(column)

	for row in range(1, left.length() + 1):
		var current: Array[int] = [row]
		for column in range(1, right.length() + 1):
			var cost := 0 if left[row - 1] == right[column - 1] else 1
			current.append(min(
				current[column - 1] + 1,
				previous[column] + 1,
				previous[column - 1] + cost
			))
		previous = current
	return previous[right.length()]


func _pretty_name(api_name: String) -> String:
	return api_name.replace("-", " ").capitalize()


func _show_error(message: String) -> void:
	status_label.text = message
	status_label.visible = true
	status_label.add_theme_color_override("font_color", Color("#ff6b6b"))
	entry.clear()
	entry.grab_focus()
	entry.edit()


func _stumped() -> void:
	_end_run("Gave up!")


func _end_run(reason: String) -> void:
	run_over = true
	DisplayServer.virtual_keyboard_hide()
	entry.visible = false
	stumped_button.visible = false
	answers_scroll.visible = false
	suggestions_scroll.visible = true
	restart_button.visible = true

	var possible := _available_names_for_letter(LETTERS[letter_index])
	var pretty: Array[String] = []
	for name in possible:
		pretty.append(_pretty_name(name))
	var answer_text := ", ".join(pretty) if not pretty.is_empty() else "No unused answers remained."
	suggestions_label.text = "Possible %s answers:\n\n%s" % [LETTERS[letter_index], answer_text]
	status_label.text = "%s  %d alphabet(s), %d Pokémon." % [reason, rounds_completed, answers.size()]
	status_label.visible = true
	_update_screen()


func _update_screen() -> void:
	status_label.remove_theme_color_override("font_color")
	progress_label.text = "Alphabet %d  •  %d / 26" % [rounds_completed + 1, letter_index]
	letter_label.text = LETTERS[letter_index]


func _restart() -> void:
	letter_index = 0
	rounds_completed = 0
	run_over = false
	answers.clear()
	used_names.clear()
	for row in recent_rows:
		if is_instance_valid(row):
			row.queue_free()
	recent_rows.clear()
	for child in answers_grid.get_children():
		child.queue_free()
	entry.visible = true
	stumped_button.visible = true
	answers_scroll.visible = true
	suggestions_scroll.visible = false
	restart_button.visible = false
	status_label.text = ""
	status_label.visible = false
	_skip_unavailable_letters()
	_update_screen()
	_open_keyboard()
