extends Control

var questions = []
var current_question

const HAMMY_SPRITE_SHEET_1 = preload("res://aseprite/hammies/hammy sprite sheet1.png")
const HAMMY_SPRITE_SHEET_2 = preload("res://aseprite/hammies/hammy sprite sheet2.png")
const HAMMY_SPRITE_SHEET_3 = preload("res://aseprite/hammies/hammy sprite sheet3.png")
const HAMMY_SPRITE_SHEET_4 = preload("res://aseprite/hammies/hammy sprite sheet4.png")
const HAMMY_SPRITE_SHEET_5 = preload("res://aseprite/hammies/hammy sprite sheet5.png")
const HAMMY_SPRITE_SHEET_6 = preload("res://aseprite/hammies/hammy sprite sheet6.png")
const HAMMY_SPRITE_SHEET_7 = preload("res://aseprite/hammies/hammy sprite sheet7.png")
const HAMMY_SPRITE_SHEET_8 = preload("res://aseprite/hammies/hammy sprite sheet8.png")
const HAMMY_SPRITE_SHEET_9 = preload("res://aseprite/hammies/hammy sprite sheet9.png")
const HAMMY_SPRITE_SHEET_10 = preload("res://aseprite/hammies/hammy sprite sheet10.png")
var hammy_sprites = [HAMMY_SPRITE_SHEET_1, HAMMY_SPRITE_SHEET_2, HAMMY_SPRITE_SHEET_3,
	HAMMY_SPRITE_SHEET_4, HAMMY_SPRITE_SHEET_5, HAMMY_SPRITE_SHEET_6,
	HAMMY_SPRITE_SHEET_7, HAMMY_SPRITE_SHEET_8, HAMMY_SPRITE_SHEET_9, HAMMY_SPRITE_SHEET_10]

var unlocked_hammies = 0;
const LOCAL_STORAGE_KEY = "multi_bingo_hammy_count"

func _ready():
	add_level_buttons()
	unlocked_hammies = load_from_localstorage()

func load_from_localstorage() -> int:
	if not OS.has_feature("web"):
		print("Not running in a web browser environment.")
		return 0
	var js_code := "localStorage.getItem('%s');" %LOCAL_STORAGE_KEY
	var result = JavaScriptBridge.eval(js_code)
	return int(result)

func save_to_localstorage():
	if not OS.has_feature("web"):
		print("Not running in a web browser environment.")
		return

	# JavaScript code to get a specific cookie value
	var js_code := "localStorage.setItem('%s', JSON.stringify(%s));" %[LOCAL_STORAGE_KEY, str(unlocked_hammies)]

	# Execute the JavaScript code and get the result
	var result = JavaScriptBridge.eval(js_code)

	if result != "":
		print("Found cookie '%s' with value: %s" % [name, result])
	else:
		print("Cookie '%s' not found." % name)
	return result


func reset():
	%WinPanel.hide()
	%Game.hide()
	%CritterCollection.hide()
	%StartMenu.show()

func play(number: int):
	%StartMenu.hide()
	generate_questions(number)
	add_answer_buttons()
	questions.shuffle()
	next_question()
	%Game.show()

func show_critters():
	%StartMenu.hide()
	%CritterCollection.show()
	for c in %CritterList.get_children():
		c.queue_free()
	for i in range(0, 10):
		var pet_tr = TextureRect.new()
		pet_tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pet_tr.custom_minimum_size = Vector2(100, 100)
		%CritterList.add_child(pet_tr)
		if i < unlocked_hammies:
			pet_tr.texture = hammy_sprites[i]
		else:
			pet_tr.texture = load("res://aseprite/buttons/buttons4.png")
			pass
			# TODO question mark or something
			

func answer(number: int, button: Button):
	if number == current_question.product:
		var button_index = button.get_index()
		%BingoGrid.remove_child(button)
		var pet_tr = TextureRect.new()
		pet_tr.texture = hammy_sprites.pick_random()
		pet_tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pet_tr.custom_minimum_size = Vector2(100, 100)
		%BingoGrid.add_child(pet_tr)
		%BingoGrid.move_child(pet_tr, button_index)
		if check_bingo():
			win()
		else:
			next_question()

func win():
	unlocked_hammies += 1
	%UnlockedTR.texture = hammy_sprites[unlocked_hammies - 1]
	save_to_localstorage()
	# Get the size of the main viewport
	var viewport_size = get_viewport_rect().size
	# Set the global position of the Position2D node to the center
	# The center is half the width and half the height of the viewport
	%CPUParticles2D.global_position = Vector2(viewport_size.x / 2.0, 0)
	(%CPUParticles2D as CPUParticles2D).emitting = true
	(%CPUParticles2D as CPUParticles2D).texture = hammy_sprites[unlocked_hammies - 1]
	%WinPanel.show()

const winning_combos = [
	[ 0,  1,  2,  3,  4],
	[ 5,  6,  7,  8,  9],
	[10, 11, 12, 13, 14],
	[15, 16, 17, 18, 19],
	[20, 21, 23, 23, 24],
	[0, 5, 10, 15, 20],
	[1, 6, 11, 16, 21],
	[2, 7, 12, 17, 22],
	[3, 8, 13, 18, 23],
	[4, 9, 14, 19, 24],
	[0, 6, 12, 18, 24],
	[4, 8, 12, 16, 20]
]

func check_bingo() -> bool:
	var indeces: Array[int] = []
	for c in %BingoGrid.get_children():
		if c is TextureRect:
			indeces.append(c.get_index())
	for combo in winning_combos:
		if contains_all(indeces, combo):
			return true
	return false


func contains_all(a: Array, b: Array) -> bool:
	for item in b:
		if not a.has(item):
			return false
	return true
	

#region not public-facing

func add_level_buttons():
	for i in range(1, 13):
		var button = Button.new()
		button.text = str(i)
		button.pressed.connect(play.bind(i))
		button.custom_minimum_size = Vector2(100, 100)
		%LevelButtons.add_child(button)

func generate_questions(number: int):
	questions = []
	generate_some_questions(number)
	generate_some_questions(number)
	questions.append({
		"m1": number,
		"m2": 0,
		"product": 0
	})
	questions.shuffle()

func generate_some_questions(number: int):
	for i in range(1, 13):
		var new_q = {
			"m1": number,
			"m2": i,
			"product": number * i
		}
		questions.append(new_q)

func add_answer_buttons():
	for c in %BingoGrid.get_children():
		c.queue_free()
	
	for q in questions:
		var button = Button.new()
		button.text = str(q.product)
		button.pressed.connect(answer.bind(q.product, button))
		button.custom_minimum_size = Vector2(100, 100)
		%BingoGrid.add_child(button)

func next_question():
	current_question = questions.pop_front()
	var q_text = str(current_question.m1) + " × " + str(current_question.m2) + " = ?"
	%Question.text = q_text

#endregion
