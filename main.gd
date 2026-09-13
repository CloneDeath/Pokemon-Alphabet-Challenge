extends Control

const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const POKEAPI_URL := "https://pokeapi.co/api/v2/pokemon-species?limit=2000"
const SPRITE_URL := "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/%d.png"
const SHINY_SPRITE_URL := "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/%d.png"
const FONT_URL := "https://raw.githubusercontent.com/google/fonts/main/ofl/fredoka/Fredoka%5Bwdth%2Cwght%5D.ttf"
const SAVE_PATH := "user://pokedex.json"
const ACTIVE_RUN_PATH := "user://active_run.json"
const STARTER_NAMES := {
	"bulbasaur": true, "charmander": true, "squirtle": true,
	"chikorita": true, "cyndaquil": true, "totodile": true,
	"treecko": true, "torchic": true, "mudkip": true,
	"turtwig": true, "chimchar": true, "piplup": true,
	"snivy": true, "tepig": true, "oshawott": true,
	"chespin": true, "fennekin": true, "froakie": true,
	"rowlet": true, "litten": true, "popplio": true,
	"grookey": true, "scorbunny": true, "sobble": true,
	"sprigatito": true, "fuecoco": true, "quaxly": true
}
const EEVEELUTIONS := {
	"vaporeon": true, "jolteon": true, "flareon": true, "espeon": true,
	"umbreon": true, "leafeon": true, "glaceon": true, "sylveon": true
}
const STARTER_DESCENDANTS := {
	"ivysaur": true, "venusaur": true, "charmeleon": true, "charizard": true, "wartortle": true, "blastoise": true,
	"bayleef": true, "meganium": true, "quilava": true, "typhlosion": true, "croconaw": true, "feraligatr": true,
	"grovyle": true, "sceptile": true, "combusken": true, "blaziken": true, "marshtomp": true, "swampert": true,
	"grotle": true, "torterra": true, "monferno": true, "infernape": true, "prinplup": true, "empoleon": true,
	"servine": true, "serperior": true, "pignite": true, "emboar": true, "dewott": true, "samurott": true,
	"quilladin": true, "chesnaught": true, "braixen": true, "delphox": true, "frogadier": true, "greninja": true,
	"dartrix": true, "decidueye": true, "torracat": true, "incineroar": true, "brionne": true, "primarina": true,
	"thwackey": true, "rillaboom": true, "raboot": true, "cinderace": true, "drizzile": true, "inteleon": true,
	"floragato": true, "meowscarada": true, "crocalor": true, "skeledirge": true, "quaxwell": true, "quaquaval": true
}
const LEGENDARY_NAMES := {
	"articuno": true, "zapdos": true, "moltres": true, "mewtwo": true, "raikou": true, "entei": true, "suicune": true, "lugia": true, "ho-oh": true,
	"regirock": true, "regice": true, "registeel": true, "latias": true, "latios": true, "kyogre": true, "groudon": true, "rayquaza": true,
	"uxie": true, "mesprit": true, "azelf": true, "dialga": true, "palkia": true, "heatran": true, "regigigas": true, "giratina": true, "cresselia": true,
	"cobalion": true, "terrakion": true, "virizion": true, "tornadus": true, "thundurus": true, "reshiram": true, "zekrom": true, "landorus": true, "kyurem": true,
	"xerneas": true, "yveltal": true, "zygarde": true, "type-null": true, "silvally": true, "tapu-koko": true, "tapu-lele": true, "tapu-bulu": true, "tapu-fini": true,
	"cosmog": true, "cosmoem": true, "solgaleo": true, "lunala": true, "necrozma": true, "zacian": true, "zamazenta": true, "eternatus": true, "kubfu": true,
	"urshifu": true, "regieleki": true, "regidrago": true, "glastrier": true, "spectrier": true, "calyrex": true, "enamorus": true,
	"wo-chien": true, "chien-pao": true, "ting-lu": true, "chi-yu": true, "koraidon": true, "miraidon": true, "okidogi": true, "munkidori": true,
	"fezandipiti": true, "ogerpon": true, "terapagos": true
}
const MYTHICAL_NAMES := {
	"mew": true, "celebi": true, "jirachi": true, "deoxys": true, "phione": true, "manaphy": true, "darkrai": true, "shaymin": true, "arceus": true,
	"victini": true, "keldeo": true, "meloetta": true, "genesect": true, "diancie": true, "hoopa": true, "volcanion": true, "magearna": true,
	"marshadow": true, "zeraora": true, "meltan": true, "melmetal": true, "zarude": true, "pecharunt": true
}
const BUILD_INFO = preload("res://build_info.gd")

var letter_index := 0
var rounds_completed := 0
var answers: Array[String] = []
var used_names: Dictionary = {}
var pokemon_names: Dictionary = {}
var validation_ready := false
var run_over := false
var run_saved := false
var hints_remaining := 3
var has_saved_run := false
var active_hint_text := ""
var current_run_names: Array[String] = []
var current_run_shinies: Dictionary = {}
var current_round_entries: Array[Dictionary] = []
var completed_round_entries: Array = []
var pokedex_data: Dictionary = {}

var recent_rows: Array[HBoxContainer] = []
var letter_label: Label
var current_row: HBoxContainer
var recent_list: VBoxContainer
var hint_label: Label
var entry: LineEdit
var status_label: Label
var progress_label: Label
var answers_scroll: ScrollContainer
var answers_grid: GridContainer
var grid_name_label: Label
var completed_rounds_scroll: ScrollContainer
var completed_rounds_grid: VBoxContainer
var suggestions_scroll: ScrollContainer
var suggestions_label: Label
var suggestions_grid: HBoxContainer
var stumped_button: Button
var hint_button: Button
var info_popup: Label
var results_buttons: HBoxContainer
var try_again_button: Button
var restart_button: Button
var give_up_confirmation: ConfirmationDialog
var game_margin: MarginContainer
var menu_overlay: Control
var pokedex_overlay: Control
var pokedex_button: Button
var resume_button: Button
var pokedex_list: VBoxContainer
var pokedex_grids: Array[GridContainer] = []


func _ready() -> void:
	_load_save()
	_load_active_run()
	_build_ui()
	get_viewport().size_changed.connect(_update_grid_columns)
	_update_grid_columns()
	_update_screen()
	_load_theme_font()
	_load_pokemon_names()
	_show_main_menu()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#09142d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var build_label := Label.new()
	build_label.text = BUILD_INFO.LABEL
	build_label.z_index = 100
	build_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	build_label.add_theme_font_size_override("font_size", 12)
	build_label.add_theme_color_override("font_color", Color("#8290ad"))
	build_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	build_label.position = Vector2(-150, 8)
	build_label.size = Vector2(138, 22)
	add_child(build_label)

	game_margin = MarginContainer.new()
	var margin := game_margin
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_BEGIN
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

	current_row = HBoxContainer.new()
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

	hint_label = Label.new()
	hint_label.custom_minimum_size = Vector2(102, 86)
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color("#8ee8d0"))
	current_row.add_child(hint_label)

	grid_name_label = Label.new()
	grid_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grid_name_label.add_theme_font_size_override("font_size", 13)
	grid_name_label.add_theme_color_override("font_color", Color("#aebbd4"))
	grid_name_label.custom_minimum_size = Vector2(0, 18)
	grid_name_label.visible = false
	layout.add_child(grid_name_label)

	completed_rounds_scroll = ScrollContainer.new()
	completed_rounds_scroll.visible = false
	completed_rounds_scroll.custom_minimum_size = Vector2(0, 78)
	completed_rounds_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	completed_rounds_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	completed_rounds_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(completed_rounds_scroll)

	completed_rounds_grid = VBoxContainer.new()
	completed_rounds_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	completed_rounds_grid.alignment = BoxContainer.ALIGNMENT_BEGIN
	completed_rounds_grid.add_theme_constant_override("separation", 6)
	completed_rounds_scroll.add_child(completed_rounds_grid)

	answers_scroll = ScrollContainer.new()
	answers_scroll.custom_minimum_size = Vector2(0, 86)
	answers_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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
	stumped_button.text = "Give Up"
	stumped_button.focus_mode = Control.FOCUS_NONE
	stumped_button.add_theme_color_override("font_color", Color.WHITE)
	stumped_button.add_theme_font_size_override("font_size", 13)
	stumped_button.custom_minimum_size = Vector2(96, 0)
	stumped_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var give_up_style := StyleBoxFlat.new()
	give_up_style.bg_color = Color("#b83a4b")
	give_up_style.corner_radius_top_left = 8
	give_up_style.corner_radius_top_right = 8
	give_up_style.corner_radius_bottom_left = 8
	give_up_style.corner_radius_bottom_right = 8
	give_up_style.content_margin_top = 5
	give_up_style.content_margin_bottom = 5
	stumped_button.add_theme_stylebox_override("normal", give_up_style)
	stumped_button.pressed.connect(_ask_give_up)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	layout.add_child(action_row)
	action_row.add_child(stumped_button)

	hint_button = Button.new()
	hint_button.focus_mode = Control.FOCUS_NONE
	hint_button.custom_minimum_size = Vector2(112, 0)
	hint_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_button.add_theme_color_override("font_color", Color("#09213a"))
	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color = Color("#79d7f2")
	hint_style.corner_radius_top_left = 8
	hint_style.corner_radius_top_right = 8
	hint_style.corner_radius_bottom_left = 8
	hint_style.corner_radius_bottom_right = 8
	hint_style.content_margin_top = 6
	hint_style.content_margin_bottom = 6
	hint_button.add_theme_stylebox_override("normal", hint_style)
	var hint_hover_style := hint_style.duplicate()
	hint_hover_style.bg_color = Color("#a4e8f8")
	hint_button.add_theme_stylebox_override("hover", hint_hover_style)
	var hint_pressed_style := hint_style.duplicate()
	hint_pressed_style.bg_color = Color("#55b9dc")
	hint_button.add_theme_stylebox_override("pressed", hint_pressed_style)
	hint_button.pressed.connect(_use_hint)
	action_row.add_child(hint_button)
	_update_hint_button()

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 22)
	status_label.visible = false
	layout.add_child(status_label)

	suggestions_scroll = ScrollContainer.new()
	suggestions_scroll.visible = false
	suggestions_scroll.custom_minimum_size = Vector2(0, 112)
	suggestions_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	suggestions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(suggestions_scroll)

	var suggestions_layout := VBoxContainer.new()
	suggestions_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suggestions_layout.add_theme_constant_override("separation", 4)
	suggestions_scroll.add_child(suggestions_layout)

	suggestions_label = Label.new()
	suggestions_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suggestions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	suggestions_label.add_theme_font_size_override("font_size", 15)
	suggestions_layout.add_child(suggestions_label)

	suggestions_grid = HBoxContainer.new()
	suggestions_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	suggestions_grid.add_theme_constant_override("separation", 10)
	suggestions_layout.add_child(suggestions_grid)

	# Keep controls above content that the phone keyboard may cover.
	layout.move_child(input_row, 2)
	layout.move_child(action_row, 3)
	layout.move_child(status_label, 4)
	layout.move_child(completed_rounds_scroll, answers_scroll.get_index() + 1)

	results_buttons = HBoxContainer.new()
	results_buttons.visible = false
	results_buttons.add_theme_constant_override("separation", 7)
	layout.add_child(results_buttons)

	try_again_button = Button.new()
	try_again_button.text = "Try Again"
	try_again_button.custom_minimum_size = Vector2(0, 48)
	try_again_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	try_again_button.pressed.connect(_start_challenge)
	results_buttons.add_child(try_again_button)

	var results_pokedex_button := Button.new()
	results_pokedex_button.text = "Pokédex"
	results_pokedex_button.custom_minimum_size = Vector2(0, 48)
	results_pokedex_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results_pokedex_button.pressed.connect(_show_pokedex)
	results_buttons.add_child(results_pokedex_button)

	restart_button = Button.new()
	restart_button.text = "Return to Menu"
	restart_button.custom_minimum_size = Vector2(0, 48)
	restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_button.add_theme_color_override("font_color", Color("#09142d"))
	var menu_style := StyleBoxFlat.new()
	menu_style.bg_color = Color("#ffcb05")
	menu_style.corner_radius_top_left = 8
	menu_style.corner_radius_top_right = 8
	menu_style.corner_radius_bottom_left = 8
	menu_style.corner_radius_bottom_right = 8
	restart_button.add_theme_stylebox_override("normal", menu_style)
	restart_button.pressed.connect(_show_main_menu)
	results_buttons.add_child(restart_button)

	give_up_confirmation = ConfirmationDialog.new()
	give_up_confirmation.title = "Give up?"
	give_up_confirmation.dialog_text = "Are you sure you want to end this run?"
	give_up_confirmation.ok_button_text = "Give Up"
	give_up_confirmation.cancel_button_text = "Keep Playing"
	give_up_confirmation.confirmed.connect(_confirm_stumped)
	add_child(give_up_confirmation)

	info_popup = Label.new()
	info_popup.visible = false
	info_popup.z_index = 20
	info_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_popup.add_theme_font_size_override("font_size", 16)
	info_popup.add_theme_color_override("font_color", Color.WHITE)
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color("#30486f")
	info_style.corner_radius_top_left = 10
	info_style.corner_radius_top_right = 10
	info_style.corner_radius_bottom_left = 10
	info_style.corner_radius_bottom_right = 10
	info_style.content_margin_left = 14
	info_style.content_margin_right = 14
	info_style.content_margin_top = 8
	info_style.content_margin_bottom = 8
	info_popup.add_theme_stylebox_override("normal", info_style)
	info_popup.set_anchors_preset(Control.PRESET_CENTER_TOP)
	info_popup.position = Vector2(-95, 82)
	info_popup.size = Vector2(190, 42)
	add_child(info_popup)

	_build_main_menu()
	_build_pokedex_screen()


func _build_main_menu() -> void:
	menu_overlay = Control.new()
	menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_overlay)

	var background := ColorRect.new()
	background.color = Color("#09142d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_child(center)

	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(280, 0)
	menu.add_theme_constant_override("separation", 18)
	center.add_child(menu)

	var title := Label.new()
	title.text = "POKÉMON\nALPHABET CHALLENGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#ffcb05"))
	menu.add_child(title)

	var run_buttons := HBoxContainer.new()
	run_buttons.add_theme_constant_override("separation", 8)
	menu.add_child(run_buttons)

	resume_button = Button.new()
	resume_button.text = "Resume"
	resume_button.visible = has_saved_run
	resume_button.disabled = not validation_ready
	resume_button.custom_minimum_size = Vector2(0, 54)
	resume_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume_button.add_theme_font_size_override("font_size", 17)
	resume_button.pressed.connect(_resume_challenge)
	run_buttons.add_child(resume_button)

	var start_button := Button.new()
	start_button.text = "Start New"
	start_button.custom_minimum_size = Vector2(0, 54)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.add_theme_font_size_override("font_size", 17)
	start_button.pressed.connect(_start_challenge)
	run_buttons.add_child(start_button)

	pokedex_button = Button.new()
	pokedex_button.text = "Pokédex"
	pokedex_button.custom_minimum_size = Vector2(0, 48)
	pokedex_button.pressed.connect(_show_pokedex)
	menu.add_child(pokedex_button)


func _build_pokedex_screen() -> void:
	pokedex_overlay = Control.new()
	pokedex_overlay.visible = false
	pokedex_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(pokedex_overlay)

	var background := ColorRect.new()
	background.color = Color("#09142d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pokedex_overlay.add_child(background)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pokedex_overlay.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "POKÉDEX"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#ffcb05"))
	layout.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	pokedex_list = VBoxContainer.new()
	pokedex_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pokedex_list.add_theme_constant_override("separation", 6)
	scroll.add_child(pokedex_list)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(0, 46)
	back_button.pressed.connect(_show_main_menu)
	layout.add_child(back_button)


func _show_main_menu() -> void:
	DisplayServer.virtual_keyboard_hide()
	game_margin.visible = false
	pokedex_overlay.visible = false
	menu_overlay.visible = true
	pokedex_button.visible = not pokedex_data.is_empty()
	resume_button.visible = has_saved_run
	resume_button.disabled = not validation_ready


func _start_challenge() -> void:
	_delete_active_run()
	menu_overlay.visible = false
	pokedex_overlay.visible = false
	game_margin.visible = true
	_reset_run()
	_save_active_run()
	_open_keyboard()


func _resume_challenge() -> void:
	if not has_saved_run or not validation_ready:
		return
	menu_overlay.visible = false
	pokedex_overlay.visible = false
	game_margin.visible = true
	_rebuild_completed_round_squares()
	if not completed_round_entries.is_empty():
		completed_rounds_scroll.visible = true
	for item in current_round_entries:
		var data: Dictionary = item
		_add_answer_card(String(data.display_name), String(data.name), bool(data.shiny), false)
	_update_screen()
	hint_label.text = active_hint_text
	_update_hint_button()
	_open_keyboard()


func _show_pokedex() -> void:
	menu_overlay.visible = false
	pokedex_overlay.visible = true
	_populate_pokedex()


func _populate_pokedex() -> void:
	for child in pokedex_list.get_children():
		child.queue_free()
	pokedex_grids.clear()

	for letter in LETTERS:
		var total := 0
		var guessed_names: Array[String] = []
		for api_name: String in pokemon_names:
			if api_name.left(1).to_upper() == letter:
				total += 1
				if pokedex_data.has(api_name):
					guessed_names.append(api_name)
		guessed_names.sort()

		var header := Label.new()
		header.text = "%s  (%d/%d)" % [letter, guessed_names.size(), total]
		header.add_theme_font_size_override("font_size", 20)
		header.add_theme_color_override("font_color", Color("#ffcb05"))
		header.add_theme_constant_override("outline_size", 3)
		header.add_theme_color_override("font_outline_color", Color("#193b70"))
		pokedex_list.add_child(header)

		var grid := GridContainer.new()
		grid.columns = clampi(int((get_viewport_rect().size.x - 36.0) / 104.0), 2, 5)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 8)
		pokedex_list.add_child(grid)
		pokedex_grids.append(grid)

		for api_name in guessed_names:
			var record: Dictionary = pokedex_data[api_name]
			var card := VBoxContainer.new()
			card.custom_minimum_size = Vector2(90, 92)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.alignment = BoxContainer.ALIGNMENT_CENTER
			grid.add_child(card)

			var sprite := TextureRect.new()
			sprite.custom_minimum_size = Vector2(62, 62)
			sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			card.add_child(sprite)

			var details := Label.new()
			details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			details.add_theme_font_size_override("font_size", 12)
			var count := int(record.get("count", 0))
			var shiny_count := int(record.get("shiny_count", 0))
			details.text = "%s\n×%d" % [_pretty_name(api_name), count]
			if shiny_count > 0:
				details.text += "  Shiny: %d" % shiny_count
			card.add_child(details)

			var pokemon_id := int(record.get("id", 0))
			if pokemon_id > 0:
				_load_sprite_by_id(pokemon_id, sprite)


func _load_sprite_by_id(pokemon_id: int, target: TextureRect) -> void:
	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_sprite_loaded.bind(request, target, false, false))
	request.request(SPRITE_URL % pokemon_id)


func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		pokedex_data = parsed


func _load_active_run() -> void:
	if not FileAccess.file_exists(ACTIVE_RUN_PATH):
		return
	var file := FileAccess.open(ACTIVE_RUN_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	letter_index = int(data.get("letter_index", 0))
	rounds_completed = int(data.get("rounds_completed", 0))
	hints_remaining = int(data.get("hints_remaining", 3))
	active_hint_text = String(data.get("active_hint_text", ""))
	used_names = Dictionary(data.get("used_names", {}))
	current_run_shinies = Dictionary(data.get("current_run_shinies", {}))
	for value in data.get("answers", []):
		answers.append(String(value))
	for value in data.get("current_run_names", []):
		current_run_names.append(String(value))
	for value in data.get("current_round_entries", []):
		current_round_entries.append(Dictionary(value))
	for value in data.get("completed_round_entries", []):
		completed_round_entries.append(Array(value))
	has_saved_run = true


func _save_active_run() -> void:
	if run_over:
		return
	var data := {
		"letter_index": letter_index,
		"rounds_completed": rounds_completed,
		"hints_remaining": hints_remaining,
		"active_hint_text": active_hint_text,
		"answers": answers,
		"used_names": used_names,
		"current_run_names": current_run_names,
		"current_run_shinies": current_run_shinies,
		"current_round_entries": current_round_entries,
		"completed_round_entries": completed_round_entries
	}
	var file := FileAccess.open(ACTIVE_RUN_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
		has_saved_run = true


func _delete_active_run() -> void:
	has_saved_run = false
	if FileAccess.file_exists(ACTIVE_RUN_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ACTIVE_RUN_PATH))


func _save_current_run() -> void:
	if run_saved or current_run_names.is_empty():
		return
	for api_name in current_run_names:
		var record: Dictionary = pokedex_data.get(api_name, {})
		record["count"] = int(record.get("count", 0)) + 1
		record["shiny_count"] = int(record.get("shiny_count", 0)) + int(current_run_shinies.get(api_name, 0))
		record["id"] = int(pokemon_names.get(api_name, record.get("id", 0)))
		pokedex_data[api_name] = record
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(pokedex_data))
	run_saved = true


func _update_grid_columns() -> void:
	if not is_instance_valid(answers_grid):
		return
	var available_width := get_viewport_rect().size.x - 32.0
	answers_grid.columns = clampi(int(available_width / 38.0), 6, 12)
	for grid in pokedex_grids:
		if is_instance_valid(grid):
			grid.columns = clampi(int(available_width / 104.0), 2, 5)


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


func _load_theme_font() -> void:
	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_theme_font_loaded.bind(request))
	request.request(FONT_URL)


func _on_theme_font_loaded(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	request: HTTPRequest
) -> void:
	request.queue_free()
	if response_code != 200:
		return
	var pixel_font := FontFile.new()
	pixel_font.data = body
	var game_theme := Theme.new()
	game_theme.default_font = pixel_font
	theme = game_theme


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
	if is_instance_valid(resume_button):
		resume_button.disabled = false
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
		entry.clear()
		entry.grab_focus()
		entry.edit()
		_show_info_popup("Already guessed that one")
		return

	used_names[api_name] = true
	current_run_names.append(api_name)
	var shiny := randi_range(1, 4096) == 1
	if shiny:
		current_run_shinies[api_name] = int(current_run_shinies.get(api_name, 0)) + 1
	current_round_entries.append({"name": api_name, "display_name": accepted_answer, "shiny": shiny})
	answers.append(accepted_answer)
	_add_answer_card(accepted_answer, api_name, shiny)
	letter_index += 1
	entry.clear()
	status_label.visible = false
	active_hint_text = ""
	hint_label.text = ""
	hint_label.scale = Vector2.ONE
	hint_label.modulate.a = 1.0

	if letter_index >= LETTERS.length():
		rounds_completed += 1
		_complete_round_display()
		letter_index = 0
	_skip_unavailable_letters()
	_update_screen()
	_save_active_run()
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
			_complete_round_display()
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


func _add_answer_card(display_name: String, api_name: String, shiny: bool, animate_sprite: bool = true) -> void:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(32, 32)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.tooltip_text = display_name
	card.gui_input.connect(_on_answer_card_input.bind(display_name))
	answers_grid.add_child(card)

	var compact_sprite := TextureRect.new()
	compact_sprite.custom_minimum_size = Vector2(30, 30)
	compact_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	compact_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	compact_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.add_child(compact_sprite)

	var recent_row := HBoxContainer.new()
	recent_row.custom_minimum_size = Vector2(0, 28)
	recent_list.add_child(recent_row)
	recent_list.move_child(recent_row, 0)
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
	if shiny:
		_animate_shiny_name(name_label)

	while recent_rows.size() > 3:
		var oldest: HBoxContainer = recent_rows.pop_front()
		oldest.queue_free()
	_update_recent_opacity()

	_load_sprite(api_name, compact_sprite, animate_sprite, shiny)
	_load_sprite(api_name, recent_sprite, false, shiny)


func _on_answer_card_input(event: InputEvent, display_name: String) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		grid_name_label.text = display_name
		grid_name_label.visible = true


func _animate_shiny_name(label: Label) -> void:
	label.add_theme_color_override("font_color", Color("#ffdc52"))
	var tween := create_tween().set_loops()
	tween.tween_property(label, "modulate", Color("#ff6b9d"), 0.35)
	tween.tween_property(label, "modulate", Color("#68e5ff"), 0.35)
	tween.tween_property(label, "modulate", Color("#9cff68"), 0.35)
	tween.tween_property(label, "modulate", Color("#ffdc52"), 0.35)


func _complete_round_display() -> void:
	hints_remaining = mini(3, hints_remaining + 1)
	_update_hint_button()
	var snapshot: Array = current_round_entries.duplicate(true)
	completed_round_entries.append(snapshot)
	current_round_entries.clear()
	_rebuild_completed_round_squares()
	for child in answers_grid.get_children():
		child.queue_free()


func _rebuild_completed_round_squares() -> void:
	for child in completed_rounds_grid.get_children():
		completed_rounds_grid.remove_child(child)
		child.queue_free()
	completed_rounds_scroll.visible = not completed_round_entries.is_empty()

	var row: HBoxContainer
	for display_index in range(completed_round_entries.size()):
		if display_index % 5 == 0:
			row = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 6)
			completed_rounds_grid.add_child(row)
		var source_index := completed_round_entries.size() - 1 - display_index
		var snapshot: Array = completed_round_entries[source_index]
		row.add_child(_create_completed_round_square(snapshot, source_index + 1))
	call_deferred("_scroll_completed_rounds_to_end")


func _create_completed_round_square(snapshot: Array, round_number: int) -> PanelContainer:
	var square := PanelContainer.new()
	square.custom_minimum_size = Vector2(58, 0)
	square.tooltip_text = "Alphabet %d — %d Pokémon" % [round_number, snapshot.size()]
	square.mouse_filter = Control.MOUSE_FILTER_STOP
	square.gui_input.connect(_on_round_square_input.bind(snapshot, round_number))

	var preview_rows := VBoxContainer.new()
	preview_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_rows.add_theme_constant_override("separation", 0)
	square.add_child(preview_rows)

	var preview_row: HBoxContainer
	for index in range(snapshot.size()):
		if index % 5 == 0:
			preview_row = HBoxContainer.new()
			preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
			preview_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview_row.add_theme_constant_override("separation", 0)
			preview_rows.add_child(preview_row)
		var item: Dictionary = snapshot[index]
		var sprite := TextureRect.new()
		sprite.custom_minimum_size = Vector2(10, 10)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_row.add_child(sprite)
		_load_sprite(String(item.name), sprite, false, bool(item.shiny))
	return square


func _scroll_completed_rounds_to_end() -> void:
	await get_tree().process_frame
	completed_rounds_scroll.scroll_vertical = 0


func _on_round_square_input(event: InputEvent, entries: Array, round_number: int) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_show_round_popup(entries, round_number)


func _show_round_popup(entries: Array, round_number: int) -> void:
	var popup := PopupPanel.new()
	add_child(popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Alphabet %d" % round_number
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#ffcb05"))
	layout.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	var popup_rows := VBoxContainer.new()
	popup_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_rows.add_theme_constant_override("separation", 6)
	scroll.add_child(popup_rows)

	var popup_row: HBoxContainer
	for index in range(entries.size()):
		if index % 5 == 0:
			popup_row = HBoxContainer.new()
			popup_row.alignment = BoxContainer.ALIGNMENT_CENTER
			popup_row.add_theme_constant_override("separation", 4)
			popup_rows.add_child(popup_row)

		var item: Dictionary = entries[index]
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(62, 76)
		card.alignment = BoxContainer.ALIGNMENT_CENTER
		popup_row.add_child(card)

		var sprite := TextureRect.new()
		sprite.custom_minimum_size = Vector2(50, 50)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		card.add_child(sprite)
		_load_sprite(String(item.name), sprite, false, bool(item.shiny))

		var label := Label.new()
		label.text = String(item.display_name)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 10)
		card.add_child(label)
		if bool(item.shiny):
			_animate_shiny_name(label)

	popup.popup_hide.connect(popup.queue_free)
	var popup_size := Vector2i(
		mini(380, int(get_viewport_rect().size.x) - 20),
		mini(620, int(get_viewport_rect().size.y) - 40)
	)
	popup.popup_centered(popup_size)


func _update_recent_opacity() -> void:
	for index in range(recent_rows.size()):
		var age := recent_rows.size() - 1 - index
		recent_rows[index].modulate.a = [1.0, 0.65, 0.4][age]


func _load_sprite(api_name: String, target: TextureRect, animate: bool, shiny: bool) -> void:
	if not pokemon_names.has(api_name):
		return
	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_sprite_loaded.bind(request, target, animate, shiny))
	var sprite_url := SHINY_SPRITE_URL if shiny else SPRITE_URL
	request.request(sprite_url % int(pokemon_names[api_name]))


func _on_sprite_loaded(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
		request: HTTPRequest,
	target: TextureRect,
	animate: bool,
	shiny: bool
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
		_animate_sprite(texture, target, shiny)


func _animate_sprite(texture: Texture2D, target: TextureRect, shiny: bool) -> void:
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
	flying.scale = Vector2(1.75, 1.75) if shiny else Vector2(1.35, 1.35)
	if shiny:
		flying.modulate = Color("#fff2a8")

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flying, "global_position", destination, 0.52 if shiny else 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(flying, "scale", Vector2.ONE, 0.52 if shiny else 0.38)
	if shiny:
		tween.tween_property(flying, "modulate", Color.WHITE, 0.52)
	tween.set_parallel(false)
	tween.tween_callback(_finish_sprite_flight.bind(flying, target, shiny))


func _finish_sprite_flight(flying: TextureRect, target: TextureRect, shiny: bool) -> void:
	var burst_position := flying.global_position + flying.size * 0.5
	if is_instance_valid(target):
		target.modulate.a = 1.0
	flying.queue_free()
	_emit_particles(burst_position, shiny)


func _emit_particles(center: Vector2, shiny: bool) -> void:
	var colors := [Color("#ff4f81"), Color("#ffcb05"), Color("#62e5ff"), Color("#8aff70"), Color("#a87cff")] if shiny else [Color("#ffcb05"), Color("#62a8e5"), Color("#ff6b6b")]
	var particle_count := 20 if shiny else 8
	for index in range(particle_count):
		var particle := ColorRect.new()
		particle.color = colors[index % colors.size()]
		particle.size = Vector2(6, 6)
		particle.global_position = center - particle.size * 0.5
		add_child(particle)
		var angle := TAU * float(index) / float(particle_count)
		var distance := 52.0 if shiny else 34.0
		var destination := particle.position + Vector2.from_angle(angle) * distance
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


func _show_info_popup(message: String) -> void:
	info_popup.text = message
	info_popup.visible = true
	info_popup.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(info_popup, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func(): info_popup.visible = false)


func _update_hint_button() -> void:
	if not is_instance_valid(hint_button):
		return
	hint_button.text = "Hint (%d)" % hints_remaining
	hint_button.disabled = hints_remaining <= 0 or run_over or (is_instance_valid(hint_label) and not hint_label.text.is_empty())


func _use_hint() -> void:
	if run_over or hints_remaining <= 0 or not validation_ready:
		return
	var possible := _available_names_for_letter(LETTERS[letter_index])
	if possible.is_empty():
		return
	var candidate := _pick_hint_candidate(possible)
	hints_remaining -= 1
	_update_hint_button()
	_save_active_run()

	if EEVEELUTIONS.has(candidate):
		_show_hint("Think of Eeveelutions.")
	elif STARTER_NAMES.has(candidate):
		_show_hint("Think of first partner Pokémon.")
	elif STARTER_DESCENDANTS.has(candidate):
		_show_hint("Think of Pokémon that evolve from a first partner.")
	elif LEGENDARY_NAMES.has(candidate):
		_show_hint("Think of Legendary Pokémon.")
	elif MYTHICAL_NAMES.has(candidate):
		_show_hint("Think of Mythical Pokémon.")
	else:
		hint_button.disabled = true
		var request := HTTPRequest.new()
		add_child(request)
		request.request_completed.connect(_on_hint_species_loaded.bind(request))
		request.request("https://pokeapi.co/api/v2/pokemon-species/%s" % candidate)


func _pick_hint_candidate(possible: Array[String]) -> String:
	for category in [EEVEELUTIONS, STARTER_NAMES, STARTER_DESCENDANTS, LEGENDARY_NAMES, MYTHICAL_NAMES]:
		for candidate in possible:
			if category.has(candidate):
				return candidate
	return possible.pick_random()


func _on_hint_species_loaded(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	request: HTTPRequest
) -> void:
	request.queue_free()
	if response_code != 200:
		hints_remaining = mini(3, hints_remaining + 1)
		_update_hint_button()
		_save_active_run()
		_show_info_popup("Hint unavailable")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		hints_remaining = mini(3, hints_remaining + 1)
		_update_hint_button()
		_save_active_run()
		return
	var generation := String(data.get("generation", {}).get("name", "unknown")).trim_prefix("generation-").to_upper()
	_show_hint("Think of Pokémon introduced in Generation %s." % generation)


func _show_hint(message: String) -> void:
	active_hint_text = message
	hint_label.text = message
	hint_label.pivot_offset = hint_label.size * 0.5
	hint_label.scale = Vector2(0.72, 0.72)
	hint_label.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(hint_label, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(hint_label, "modulate:a", 1.0, 0.16)
	_update_hint_button()
	_save_active_run()
	entry.grab_focus()
	entry.edit()


func _ask_give_up() -> void:
	DisplayServer.virtual_keyboard_hide()
	give_up_confirmation.popup_centered(Vector2i(310, 150))


func _confirm_stumped() -> void:
	_end_run("You made it to %s." % LETTERS[letter_index])


func _alphabet_count_text(count: int) -> String:
	return "%d alphabet" % count if count == 1 else "%d alphabets" % count


func _end_run(reason: String) -> void:
	run_over = true
	_save_current_run()
	_delete_active_run()
	DisplayServer.virtual_keyboard_hide()
	entry.visible = false
	stumped_button.visible = false
	hint_button.visible = false
	current_row.visible = false
	answers_scroll.visible = true
	suggestions_scroll.visible = true
	current_row.get_parent().move_child(suggestions_scroll, current_row.get_index())
	results_buttons.visible = true

	for child in suggestions_grid.get_children():
		child.queue_free()
	var possible := _available_names_for_letter(LETTERS[letter_index])
	suggestions_label.text = "Possible %s answers" % LETTERS[letter_index]
	if possible.is_empty():
		suggestions_label.text = "No unused answers remained."
	for index in range(mini(3, possible.size())):
		var api_name := possible[index]
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(82, 82)
		card.alignment = BoxContainer.ALIGNMENT_CENTER
		suggestions_grid.add_child(card)

		var sprite := TextureRect.new()
		sprite.custom_minimum_size = Vector2(62, 62)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		card.add_child(sprite)
		_load_sprite(api_name, sprite, false, false)

		var answer_label := Label.new()
		answer_label.text = _pretty_name(api_name)
		answer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		answer_label.add_theme_font_size_override("font_size", 14)
		card.add_child(answer_label)
	status_label.text = "%s  %s, %d Pokémon." % [reason, _alphabet_count_text(rounds_completed), answers.size()]
	status_label.visible = true
	_update_screen()


func _update_screen() -> void:
	status_label.remove_theme_color_override("font_color")
	progress_label.text = "Alphabet %d  •  %d / 26" % [rounds_completed + 1, letter_index]
	letter_label.text = LETTERS[letter_index]
	if not run_over:
		_update_hint_button()


func _reset_run() -> void:
	letter_index = 0
	rounds_completed = 0
	run_over = false
	run_saved = false
	hints_remaining = 3
	active_hint_text = ""
	current_run_names.clear()
	current_run_shinies.clear()
	current_round_entries.clear()
	completed_round_entries.clear()
	answers.clear()
	used_names.clear()
	for row in recent_rows:
		if is_instance_valid(row):
			row.queue_free()
	recent_rows.clear()
	for child in answers_grid.get_children():
		child.queue_free()
	for child in completed_rounds_grid.get_children():
		child.queue_free()
	completed_rounds_scroll.visible = false
	entry.visible = true
	current_row.visible = true
	stumped_button.visible = true
	hint_button.visible = true
	_update_hint_button()
	answers_scroll.visible = true
	suggestions_scroll.visible = false
	results_buttons.visible = false
	grid_name_label.visible = false
	hint_label.text = ""
	status_label.text = ""
	status_label.visible = false
	_skip_unavailable_letters()
	_update_screen()
