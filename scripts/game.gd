extends Node

@export var goals:Dictionary = {"book":false,"photo":false,"necklace":false,"mirror":false, "salt":false, "tenderizer":false, "exorcism":false}
@export var goal_display:RichTextLabel = null
@export var itemlist: ItemList = null
@export var item2icon: Dictionary = {"book":Vector2i(15,15), "photo":Vector2i(8,14), "necklace":Vector2i(15,3), "mirror":Vector2i(6,10), "salt":Vector2i(11,0), "tenderizer":Vector2i(13,0)}
@export var icon_atlas: AtlasTexture = null

@onready var fog_start: PackedByteArray = get_node("%Map/Fog").tile_map_data
@onready var map_start: PackedByteArray = get_node("%Map").tile_map_data

func _ready() -> void:
	get_tree().paused = true
	get_node("%Menu").visible = true
	get_node("%MainMenu").visible = true
	get_node("%Game").visible = false
	get_node("%UI/Game").visible = false

# Reset everything (to allow restart) and start the game
signal start_game()
func _on_start() -> void:
	# Reset
	get_node("%Map/Fog").tile_map_data = fog_start
	get_node("%Map").tile_map_data = map_start
	for goal in goals:
		goals[goal] = false
	itemlist.clear()

	# Start
	get_node("%Game").visible = true
	get_node("%UI/Game").visible = true
	get_node("%Menu").visible = false
	get_node("%MainMenu").visible = false
	get_tree().paused = false
	emit_signal("start_game")
	get_node("%Camera").make_current()
	update_goal_display()

	pass # Replace with function body.
# Set the shown location when the player updates it
func _on_player_location_update(current_room:String) -> void:
	get_node("%LocationDisplay").text = current_room

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
	itemlist.add_item(item, icon)

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
	for key in symbol_goals:
		if symbol_goals[key]:
			symbol_goals[key] = "▣"
		elif !symbol_goals[key]:
			symbol_goals[key] = "▢"

	goal_display.text = text.format(symbol_goals)

# Either lose or win the game depending on whether or not all items have been gathered
func _on_player_demom_touch(location) -> void:
	if itemlist.item_count >= 6:
		get_node("%Map").erase_cell(location)
		goals["exorcism"] = true
		update_goal_display()
		winlose(true)
	else:
		winlose(false)

# Display the correct end screen message
func winlose(win: bool) -> void:
	if win:
		get_node("%EndScreen").get_child(0).text = "You Win!"
	else:
		get_node("%EndScreen").get_child(0).text = "You Lose"
	get_tree().paused = true
	get_node("%Menu").visible = true
	get_node("%EndScreen").visible = true

# Pause the game
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = true
		get_node("%Menu").visible = true
		get_node("%PauseMenu").visible = true


func _on_unpause() -> void:
	get_tree().paused = false
	get_node("%Menu").visible = false
	get_node("%PauseMenu").visible = false
