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

var answer_cards: Array[VBoxContainer] = []
var answer_labels: Array[Label] = []
var letter_label: Label
var entry: LineEdit
var status_label: Label
var progress_label: Label
var answers_scroll: ScrollContainer
var answers_grid: GridContainer
var suggestions_scroll: ScrollContainer
var suggestions_label: Label
var submit_button: Button
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

	letter_label = Label.new()
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.add_theme_font_size_override("font_size", 72)
	letter_label.add_theme_color_override("font_color", Color("#62a8e5"))
	layout.add_child(letter_label)

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

	submit_button = Button.new()
	submit_button.text = "Submit"
	submit_button.custom_minimum_size = Vector2(78, 50)
	submit_button.focus_mode = Control.FOCUS_NONE
	submit_button.pressed.connect(func(): _submit_answer(entry.text))
	input_row.add_child(submit_button)

	stumped_button = Button.new()
	stumped_button.text = "I'm Stumped"
	stumped_button.focus_mode = Control.FOCUS_NONE
	stumped_button.pressed.connect(_stumped)
	layout.add_child(stumped_button)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 22)
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
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY or not data.has("results"):
		status_label.text = "Offline mode — starting-letter checks only."
		return

	for item in data.results:
		var name := String(item.name).to_lower()
		var url := String(item.url).trim_suffix("/")
		pokemon_names[name] = int(url.get_file())
	validation_ready = true
	status_label.text = "Pokémon list loaded. Good luck!"
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

	var message := "Nice!"
	if _normalize_name(answer) != _normalize_name(accepted_answer):
		message = "Accepted as %s!" % accepted_answer
	if letter_index >= LETTERS.length():
		rounds_completed += 1
		letter_index = 0
		message = "Alphabet %d complete — keep going!" % rounds_completed

	status_label.text = message
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
	card.custom_minimum_size = Vector2(60, 78)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	answers_grid.add_child(card)
	answer_cards.append(card)

	var sprite := TextureRect.new()
	sprite.custom_minimum_size = Vector2(54, 54)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.add_child(sprite)

	var name_label := Label.new()
	name_label.text = display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.custom_minimum_size = Vector2(60, 24)
	name_label.tooltip_text = display_name
	card.add_child(name_label)
	answer_labels.append(name_label)
	_update_answer_labels()

	if not pokemon_names.has(api_name):
		return
	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_sprite_loaded.bind(request, sprite))
	request.request(SPRITE_URL % int(pokemon_names[api_name]))


func _update_answer_labels() -> void:
	for index in range(answer_labels.size()):
		var show_name := index >= answer_labels.size() - 3
		answer_labels[index].visible = show_name
		answer_cards[index].custom_minimum_size.y = 78 if show_name else 56


func _on_sprite_loaded(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	request: HTTPRequest,
	target: TextureRect
) -> void:
	request.queue_free()
	if response_code != 200 or not is_instance_valid(target):
		return
	var image := Image.new()
	if image.load_png_from_buffer(body) == OK:
		target.texture = ImageTexture.create_from_image(image)


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
	status_label.add_theme_color_override("font_color", Color("#ff6b6b"))
	entry.clear()
	entry.grab_focus()
	entry.edit()


func _stumped() -> void:
	_end_run("I'm stumped!")


func _end_run(reason: String) -> void:
	run_over = true
	DisplayServer.virtual_keyboard_hide()
	entry.visible = false
	submit_button.visible = false
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
	answer_cards.clear()
	answer_labels.clear()
	for child in answers_grid.get_children():
		child.queue_free()
	entry.visible = true
	submit_button.visible = true
	stumped_button.visible = true
	answers_scroll.visible = true
	suggestions_scroll.visible = false
	restart_button.visible = false
	status_label.text = ""
	_skip_unavailable_letters()
	_update_screen()
	_open_keyboard()
