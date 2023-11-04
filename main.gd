extends Node

var clicked = false
var max_chip_value = 7
var max_columns = max_chip_value
var max_rows = max_chip_value + 1
@export var starting_hit_points = 2
var board = []
@export var moves = 0
var animating = false
@export var moves_per_round = 5
@export_range(0, 1) var padding_percentage = 0.1
@export var game_state = 'stopped'

var rng = RandomNumberGenerator.new()
var current_value = rng.randi_range(1, max_chip_value)

var chip_template = preload("res://chip.tscn")
var chip_texture = [
	preload("res://art/chip1.png"),
	preload("res://art/chip2.png"), 
	preload("res://art/chip3.png"), 
	preload("res://art/chip4.png"), 
	preload("res://art/chip5.png"), 
	preload("res://art/chip6.png"), 
	preload("res://art/chip7.png")
]

var new_chip_texture = preload("res://art/chip.png")
var cracked_chip_texture = preload("res://art/chip_broken.png")

var lane_width
var mode = 'blitz'

func spawn_chip(val, col, height):
	var tile = chip_template.instantiate()
	tile.get_node("Sprite2D").texture = chip_texture[val]
	tile._set_scale(lane_width)
	# tile._set_collision(Vector2(lane_width / 2, lane_width / 2))
	var row = height
	if row < 0:
		row = row * -1
	tile.set_initial_position(col, row, lane_width, get_viewport().get_visible_rect().size.x * padding_percentage / 2)
	# tile.position = Vector2(lane_width * col + lane_width/2, -1 * height * 48 + 240)
	add_child(tile)
	tile.drop(row)
	return tile

func _ready():
	start_game()
	
func pause(seconds):
	await get_tree().create_timer(seconds).timeout
	
func clear_board():
	for col in board.size():
		for row in board[col].size():
			board[col][row].val = 0
			board[col][row].toDelete = false
			if board[col][row].chip != null:
				board[col][row].chip.queue_free()
				
func start_game():
	clear_board()
	print(max_rows)
	game_state = 'running'
	lane_width = get_viewport().get_visible_rect().size.x * (1 - padding_percentage) / max_columns
	for x in max_columns:
		board.append([])
		for y in max_rows:
			board[x].append({"val": 0, "chip": null, "to_delete": false})
	if mode == 'blitz':
		# spawn a bunch of chips
		var number_of_starting_chips = 28
		var row = max_rows - 1
		while row > 0 && number_of_starting_chips > 0:
			for col in max_columns:
				board[col][row].val = rng.randi_range(1, max_chip_value)
				number_of_starting_chips -= 1
			row -= 1
		# do an initial scan_and_clear and coalesce off screen
		var clear_count = 0
		clear_count = scan_and_clear()
		while clear_count > 0:
			for i in max_columns:
				for j in max_rows:
					if board[i][j].to_delete:
						board[i][j].val = 0
						board[i][j].to_delete = false
			coalesce_board()			
			clear_count = scan_and_clear()
		# render and drop what is left
		for col in max_columns:
			row = max_rows - 1
			while row >= 0:			
				if board[col][row].val != 0:
					board[col][row].chip = spawn_chip(board[col][row].val - 1, col, -1 * row)
					await pause(.01)
				row -= 1

func coaelesce_column(col):
	var coalesce_count = 0
	var row = max_rows - 1
	while row > 0:
		if board[col][row].val == 0:
			# start looking one above
			var _row = row - 1
			var found = false
			while _row > 0 && !found:
				#  we found a tile				
				if board[col][_row].val != 0:
					found = true					
					board[col][row].val = board[col][_row].val
					board[col][row].chip = board[col][_row].chip
					if board[col][row].chip != null:
						board[col][row].chip.drop(row)
					board[col][row].to_delete = false
					board[col][_row].val = 0
					board[col][_row].to_delete = false					
					coalesce_count += 1
				else:
					_row -= 1
		row -= 1
	return coalesce_count
	
func coalesce_board():
	for col in max_columns:
		var coalesce_count = coaelesce_column(col)
		while coalesce_count > 0:
			coalesce_count = coaelesce_column(col)
		
func break_armor(col, row):
	if board[col][row].val < -1:
		board[col][row].val += 1
		if board[col][row].val == -2:
			board[col][row].chip.get_node("Sprite2D").texture = cracked_chip_texture
		else:
			if board[col][row].val == -1:
				board[col][row].val = rng.randi_range(1, max_chip_value)
				board[col][row].chip.get_node("Sprite2D").texture = chip_texture[board[col][row].val - 1]
			
		
func check_break_armor(col, row):
	var left = col - 1
	var right = col + 1
	var above = row - 1
	var below = row + 1
	
	if left >= 0:
		break_armor(left, row)
	if right < max_columns - 1:
		break_armor(right, row)
	if below < max_rows - 1:
		break_armor(col, below)
	if above >= 0:
		break_armor(col, above)	

func clear_row():
	var clear_count = 0

	for row in max_rows:
		var col = 0
		while col < max_columns:
			if board[col][row].val == 0:
				col += 1
			else:
				var run_length = 0
				var start_column = col
				while col < max_columns && board[col][row].val != 0:
					run_length += 1
					col += 1
				for i in run_length:
					if board[start_column + i][row].val == run_length && !board[start_column + i][row].to_delete:
						board[start_column + i][row].to_delete = true
						clear_count += 1
	return clear_count

func clear_column(_col):
	var col_height = 0
	var clear_count = 0
	
	# get column height
	var row = max_rows - 1
	var found = false
	while row >= 0 && !found:
		if board[_col][row].val == 0:
			found = true
		else:
			col_height += 1
			row -= 1
	
	# now check which ones to delete
	if col_height > 0:
		for _row in max_rows:
			if board[_col][_row].val == col_height:
				board[_col][_row].to_delete = true
				clear_count += 1
	return clear_count
	
func scan_and_clear():
	var clear_count = 0

	# clear the columns
	for _col in max_columns:
		clear_count += clear_column(_col)
		
	# clear the rows
	var row_clear = 0
	row_clear = clear_row()
	clear_count += row_clear
	while row_clear > 0:
		row_clear = clear_row()
		clear_count += row_clear
	return clear_count

func delete_tiles():
	var deleted_count = 0
	for col in max_columns:
		for row in max_rows:
			if board[col][row].to_delete:
				await board[col][row].chip.explode()
				board[col][row].val = 0
				board[col][row].chip.queue_free()
				board[col][row].to_delete = false
				deleted_count += 1
				await get_tree().create_timer(0.01).timeout
				check_break_armor(col, row)
	return deleted_count
	
func add_row():
	#  move everything up 1
	var col = 0
	while col < max_columns:
		# start from top row
		var row = 0
		while row < max_rows - 1:
			# if a chip below, then move it up
			if board[col][row + 1].val != 0:
				board[col][row].val = board[col][row + 1].val
				board[col][row].chip = board[col][row + 1].chip
				if board[col][row + 1].chip != null:
					board[col][row + 1].chip.move_up(row)
			row += 1
		col += 1
		
	# spawn a new row
	col = 0
	while col < max_columns:		
		var tile = chip_template.instantiate()
		tile.get_node("Sprite2D").texture = new_chip_texture
		tile._set_scale(lane_width)
		tile.set_new_chip_position(col, max_rows - 1, lane_width, get_viewport().get_visible_rect().size.x * padding_percentage / 2)
		add_child(tile)
		board[col][max_rows - 1] = {"val": -1 * starting_hit_points - 1, "chip": tile, "to_delete": false}
		col += 1
			
func check_for_game_over():
	var col = 0
	var found = false
	while col < max_columns && !found:
		if board[col][0].val != 0:
			found = true
		else:
			col += 1
	if found:
		print("found a")
		return true
	
	found = false
	col = 0
	while col < max_columns && !found:
		if board[col][1].val == 0:
			found = true
		else:
			col += 1
	if found:
		return false
	else:
		return true

func do_post_drop():
	var clear_count = scan_and_clear()
	while clear_count > 0:
		var deleted_count = await delete_tiles()
		coalesce_board()
		await get_tree().create_timer(1).timeout
		clear_count = scan_and_clear()
		
func do_drop(_col):
	if !animating:
		animating = true
		var row = 1
		var col = _col - 1
		if board[col][row].val == 0:
			moves += 1
			var found = false
			while row < max_rows && !found:
				if row == max_rows - 1 || board[col][row + 1].val != 0:
					found = true
				else:
					row += 1
			board[col][row] = {"val": current_value, "chip": spawn_chip(current_value - 1, col, row), "to_delete": false}
			await get_tree().create_timer(0.5).timeout
			do_post_drop()
			await get_tree().create_timer(0.5).timeout
			#if moves % moves_per_round == 0:
			add_row()
			await get_tree().create_timer(0.5).timeout
			if check_for_game_over():
				print("game over")
				game_state = 'stopped'
			else:
				do_post_drop()
				animating = false
				current_value = rng.randi_range(1, 7)
	
func _process(delta):
	if game_state == 'stopped':
		if Input.is_action_just_pressed("keyS"):
			start_game()
	else:
		if game_state == 'running':
			if Input.is_action_just_pressed("click"):
				clicked = true
			if Input.is_action_just_released("click"):
				clicked = false
			if Input.is_action_just_pressed("key1"):
				do_drop(1)
			if Input.is_action_just_released("key2"):
				do_drop(2)
			if Input.is_action_just_released("key3"):
				do_drop(3)
			if Input.is_action_just_released("key4"):
				do_drop(4)
			if Input.is_action_just_released("key5"):
				do_drop(5)
			if Input.is_action_just_released("key6"):
				do_drop(6)
			if Input.is_action_just_released("key7"):
				do_drop(7)
	
