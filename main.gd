extends Node

var clicked = false
var width = 7
var height = 7
var board = []
var moves = 0
var animating = false
@export var moves_per_round = 7

var rng = RandomNumberGenerator.new()
var current_value = rng.randi_range(1, 7)

var chip = preload("res://chip.tscn")
var chip_texture = [preload("res://art/chip1.png"), preload("res://art/chip2.png"), preload("res://art/chip3.png"), preload("res://art/chip4.png"), preload("res://art/chip5.png"), preload("res://art/chip6.png"), preload("res://art/chip7.png")]

var lane_width 

# Called when the node enters the scene tree for the first time.
func _ready():	
	lane_width = get_viewport().get_visible_rect().size.x/width
	for x in width:
		board.append([])
		for y in height:
			board[x].append({"val": 0, "chip": null, "to_delete": false})
			
func coaelesce_column(col):
	var coalesce_count = 0
	var row = height - 1
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
					board[col][row].to_delete = false
					board[col][_row].val = 0
					board[col][_row].to_delete = false					
					coalesce_count += 1
				else:
					_row -= 1
		row -= 1
	return coalesce_count
	
func coalesce_board():
	for col in width:
		var coalesce_count = 0
		coalesce_count = coaelesce_column(col)
		while coalesce_count > 0:
			coalesce_count = coaelesce_column(col)
		
func break_armor(col, row):
	if board[col][row].val < -1:
		board[col][row].val += 1
		if board[col][row].val == -1:
			board[col][row].val = rng.randi_range(1, 7)
		
func check_break_armor(col, row):
	var left = col - 1
	var right = col + 1
	var above = row - 1
	var below = row + 1
	
	if left >= 0:
		break_armor(left, row)
	if right < width - 1:
		break_armor(right, row)
	if below < height - 1:
		break_armor(col, below)
	if above >= 0:
		break_armor(col, above)	

func clear_row():
	var clear_count = 0

	for row in height:
		var col = 0
		while col < width:
			if board[col][row].val == 0:
				col += 1
			else:
				var run_length = 0
				var start_column = col
				while col < width && board[col][row].val != 0:
					run_length += 1
					col += 1
				for i in run_length:
					if board[start_column + i][row].val == run_length && !board[start_column + i][row].to_delete:
						board[start_column + i][row].to_delete = true
						board[start_column + i][row].chip.freeze = true
						clear_count += 1
	return clear_count

func clear_column(_col):
	var col_height = 0
	var clear_count = 0
	
	# get column height
	var row = height - 1
	var found = false
	while row >= 0 && !found:
		if board[_col][row].val == 0:
			found = true
		else:
			col_height += 1
			row -= 1
	
	# now check which ones to delete
	if col_height > 0:
		for _row in height:
			if board[_col][_row].val == col_height:
				board[_col][_row].to_delete = true
				clear_count += 1
	return clear_count
	
func scan_and_clear():
	var clear_count = 0
	
	# clear the columns
	for _col in width:
		clear_count += clear_column(_col)
		
	# clear the rows
	var row_clear = 0
	row_clear = await clear_row()
	clear_count += row_clear
	while row_clear > 0:
		row_clear = await clear_row()
		clear_count += row_clear

	return clear_count

func delete_tiles():
	var deleted_count = 0
	for col in width:
		for row in height:
			if board[col][row].to_delete:
				board[col][row].val = 0
				board[col][row].chip.queue_free()
				board[col][row].to_delete = false
				deleted_count += 1
				await get_tree().create_timer(0.1).timeout
	return deleted_count
	
func do_drop(_col):
	if !animating:
		animating = true
		var row = 0
		var col = _col - 1
		if board[col][row].val == 0:
			moves += 1
			var tile = chip.instantiate()
			tile.get_node("Sprite2D").texture = chip_texture[current_value - 1]
			tile.get_node("Sprite2D").scale = Vector2(lane_width / 48, lane_width / 48)
			tile.get_node("CollisionShape2D").shape.extents = Vector2(lane_width / 2, lane_width / 2)
			tile.position = Vector2(lane_width * col + lane_width/2, 0)
			add_child(tile)
			var found = false
			while row < height && !found:
				if row == height - 1 || board[col][row + 1].val != 0:
					found = true
				else:
					row += 1
			board[col][row] = {"val": current_value, "chip": tile, "to_delete": false}
		await get_tree().create_timer(0.5).timeout
		var clear_count = await scan_and_clear()
		while clear_count > 0:
			var deleted_count = await delete_tiles()
			await coalesce_board()
			await get_tree().create_timer(0.5).timeout
			clear_count = await scan_and_clear()
		animating = false
		current_value = rng.randi_range(1, 7)
	
func _process(delta):
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
	
