extends Node

@export var goals:Dictionary = {"book":false,"photo":false,"necklace":false,"mirror":false, "salt":false, "tenderizer":false, "exorcism":false}
@export var goal_display:RichTextLabel = null
@export var itemlist: ItemList = null
@export var item2icon: Dictionary = {"book":Vector2i(15,15), "photo":Vector2i(8,14), "necklace":Vector2i(15,3), "mirror":Vector2i(6,10), "salt":Vector2i(11,0), "tenderizer":Vector2i(13,0)}
@export var item_display_name: Dictionary = {"book":"Demonology Book","photo":"Family Photo","necklace":"Grandmother's Necklace","mirror":"Hand Mirror", "salt":"Salt", "tenderizer":"Meat Tenderizer"}
@export var icon_atlas: AtlasTexture = null

@onready var map_start: PackedByteArray =$%Map.tile_map_data

signal play_sound(path: String) 

func _ready() -> void:
	get_tree().paused = true
	$%Menu.visible = true
	$%MainMenu.visible = true
	$%Game.visible = false
	$%UI/Game.visible = false
	$%OpeningText.visible = false
	connect_buttons()

signal anykey()
func _input(event: InputEvent) -> void:
	# If while the opening text is visible, a key is pressed emit "anykey"
	if $%OpeningText.visible && event is InputEventKey:
		emit_signal("anykey")
	if event.is_action_pressed("pause"):
		_on_pause()

# Reset everything (to allow restart) and start the game
signal start_game()
func _on_start() -> void:
	# Reset
	$%EndScreen.visible = false
	$%Game.visible = false
	$%UI/Game.visible = false
	$%Map.tile_map_data = map_start
	reset_fog()
	for goal in goals:
		goals[goal] = false
	itemlist.clear()


	# Show opening text until something is pressed
	$%MainMenu.visible = false
	$%OpeningText.visible = true
	await self.anykey

	# Start
	$%OpeningText.visible = false
	$%Game.visible = true
	$%UI/Game.visible = true
	$%Menu.visible = false
	get_tree().paused = false
	emit_signal("start_game")
	update_goal_display()

func reset_fog() -> void:
	var tile_array: Array[Vector2i] = $%Map.get_used_cells()
	$%Map/Fog.clear()
	for tile in tile_array:
		$%Map/Fog.set_cell(tile, 1, Vector2i(11,13))


# Set the shown location when the player updates it
func _on_player_location_update(current_room:String) -> void:
	$%LocationDisplay.text = current_room

# Update what items the player has and display it
func _on_player_item_pickup(item:String) -> void:
	#Update goals
	goals[item] = true
	update_goal_display()
	#Update inventory
	var icon: AtlasTexture = AtlasTexture.new()
	icon.atlas = icon_atlas
	icon.region = Rect2(item2icon.get(item)*20, Vector2(20,20))
	icon.filter_clip = true
	itemlist.add_item(item_display_name[item], icon)
	# Play pickup sound
	emit_signal("play_sound", "res://resources/pickup.wav")

# Display the goals and their completion status
func update_goal_display() -> void:
	var text:String = "\
 {book} Get Demonology Book\n\
 {photo} Get Family Photo\n\
 {necklace} Get Grandmother's Necklace\n\
 {mirror} Get Hand Mirror\n\
 {salt} Get Salt\n\
 {tenderizer} Get Meat Tenderizer\n\
 {exorcism} Exorcise Cennin"

	# Create a copy of 'goals' that replaces the bool with symbols
	var symbol_goals: Dictionary = goals.duplicate()
	# Replace the boolean state of the keys with filled or unfilled boxes for display
	for key in symbol_goals:
		if symbol_goals[key]:
			symbol_goals[key] = "▣"
		elif !symbol_goals[key]:
			symbol_goals[key] = "▢"

	goal_display.text = text.format(symbol_goals)

# Either lose or win the game depending on whether or not all items have been gathered
func _on_player_demom_touch(location) -> void:
	if itemlist.item_count >= 6:
		$%Map.erase_cell(location)
		goals["exorcism"] = true
		update_goal_display()
		winlose(true)
		emit_signal("play_sound", "res://resources/victory_riff.wav")
	else:
		winlose(false)
		emit_signal("play_sound", "res://resources/lose.wav")

# Display the correct end screen message
func winlose(win: bool) -> void:
	if win:
		$%EndScreen.get_child(0).text = "You Win!"
	else:
		$%EndScreen.get_child(0).text = "You Lose"
	get_tree().paused = true
	$%Menu.visible = true
	$%EndScreen.visible = true

# Pause the game
func _on_pause() -> void:
	# If on another menu, do nothing
	if $%Menu.visible:
		return
	get_tree().paused = true
	$%Menu.visible = true
	$%PauseMenu.visible = true

func _on_unpause() -> void:
	get_tree().paused = false
	$%Menu.visible = false
	$%PauseMenu.visible = false

## Sounds
# Connect the signals of the buttons in inheritors of menu_base
func connect_buttons() -> void:
	for menu in ["EndScreen", "MainMenu", "PauseMenu"]:
		for button: BaseButton in get_node(NodePath("%%%s/Controls" % menu)).get_children():
			button.mouse_entered.connect(_on_hover)
			button.button_down.connect(_on_button_down)


# On hover over menu option play sound
func _on_hover() -> void:
	emit_signal("play_sound","res://resources/hover.wav")

# On clicking a button play sound
func _on_button_down() -> void:
	emit_signal("play_sound","res://resources/click.wav")
