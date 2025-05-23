extends Sprite2D
var Reveal = RevealTilesV2.new()

##DEBUG
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("anglecountup"):
		Reveal.angle_count += 100
		$%AngleCount.text = String("Angles: %s" % Reveal.angle_count)
	if event.is_action_pressed("anglecountdown"):
		Reveal.angle_count -= 100
		$%AngleCount.text = String("Angles: %s" % Reveal.angle_count)

# The script for handling everything related to the player
# Handles movement and inventory

@export var start_x: int = 7
@export var start_y: int = 15
@export var map: TileMapLayer = null
var code_array: PackedStringArray = ["","","","","","","","","","",""]
var valid_code: PackedStringArray = ["Enter","A","B","Right","Left","Right","Left","Down","Down","Up","Up"]

@onready var ray = self.get_child(0)
@onready var location: Vector2i
# Whether or not to allow movement to be performed. Keeps the player from moving on game start
var allow_move: bool = false

signal item_pickup(item: String)
signal demom_touch(location: Vector2i)
signal location_update(current_room: String)

# When the game starts, place the player in their starting position and reveal (The timer just allows everything else to unpause before scanning, I think, it doesn't work without it)
func _on_start() -> void:
	allow_move = false
	location = Vector2i(start_x, start_y)
	self.global_position = location * 20
	await get_tree().create_timer(.01).timeout
	Reveal.reveal(self, map, $%Map/Fog, $%Map/Visible)
	allow_move = true
	

# Movement
## Enum defining possible movement directions
enum Direction {LEFT=8, RIGHT=0, UP=12, DOWN=4}
## Move the player in the passed last_direction as long as it's not into a solid tile
func move(direction: int) -> void:
	var next_tile: Vector2i = map.get_neighbor_cell(location, direction)
	# If trying to move to a solid tile, don't
	if map.get_cell_tile_data(next_tile) != null:
		var tile_data: TileData = map.get_cell_tile_data(next_tile)
		# Check if the tile being moved to is solid, and if it is, stop the movement
		if tile_data.get_custom_data("Solid"):
			return
		# Check if the tile being moved to is an item, if it is, emit the item_pickup signal, and erase the tile
		elif tile_data.get_custom_data("Item") != "":
			emit_signal("item_pickup", tile_data.get_custom_data("Item"))
			map.erase_cell(next_tile)
		# Check if the tile being moved to is an enemy, if it is, emit the demom_touch signal
		elif tile_data.get_custom_data("Enemy"):
			emit_signal("demom_touch", next_tile)
	# Move the player
	location = next_tile
	self.global_position = location * 20
	update_location()
	# Reveal all that should be visible
	Reveal.reveal(self, map, $%Map/Fog, $%Map/Visible)


func _unhandled_input(event: InputEvent) -> void:
	if allow_move && event.is_action_pressed("left"):
		move(Direction.LEFT)
		last_direction = "left"
		repeat_timer(.35)
	if allow_move && event.is_action_pressed("right"):
		move(Direction.RIGHT)
		last_direction = "right"
		repeat_timer(.35)
	if allow_move && event.is_action_pressed("up"):
		move(Direction.UP)
		last_direction = "up"
		repeat_timer(.35)
	if allow_move && event.is_action_pressed("down"):
		move(Direction.DOWN)
		last_direction = "down"
		repeat_timer(.35)
	# Add the key input to code_array
	if !(event is InputEventKey and event.pressed):
		return
	code_array.resize(10)
	code_array.insert(0,event.as_text())
	if code_array == valid_code:
		debug_tp()

## The last moved last_direction. Used for held-key movement
var last_direction:String = ""
# Moves the player in the held last_direction and restarts the timer
func _on_repeat_input():
	if Input.is_action_pressed(last_direction):
		if last_direction == "left":
			move(Direction.LEFT)
		if last_direction == "right":
			move(Direction.RIGHT)
		if last_direction == "up":
			move(Direction.UP)
		if last_direction == "down":
			move(Direction.DOWN)
		repeat_timer(.15)
# Manages the timer for movement
func repeat_timer(time:float) -> void:
	var timer: Timer = $%Move_Timer
	if !timer.timeout.is_connected(_on_repeat_input):
		timer.timeout.connect(_on_repeat_input)
	timer.wait_time = time
	timer.start()

func update_location() -> void:
	var locations:Array = $%Areas.get_children()
	var current_room: String = "Doorway"
	for room: Area2D in locations:
		var rect: Rect2 = room.get_child(0).shape.get_rect()
		if rect.abs().has_point(self.global_position-room.global_position):
			current_room = room.name
			break
	# Set the shown location
	emit_signal("location_update", current_room)

func debug_tp() -> void:
	print_debug("tp")
	var tp_tile = map.local_to_map(map.to_local($%DebugTP.position))
	location = tp_tile
	self.global_position = tp_tile * 20
	Reveal.reveal(self, map, $%Map/Fog, $%Map/Visible)
