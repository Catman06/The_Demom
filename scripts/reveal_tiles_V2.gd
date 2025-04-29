class_name RevealTilesV2
extends Node

# A shadowcasting algorithm adapted from https://fadden.com/tech/ShadowCast.cs.txt

var player_tile: Vector2i
var map: TileMapLayer
var fog: TileMapLayer
var visible: TileMapLayer

# Clears fog and lights up the passed tile
func light(tile: Vector2i):
	fog.set_cell(tile,-1)
	visible.set_cell(tile, 1, Vector2i(11,13))

# Main function
func reveal(player: Node2D, passed_map: TileMapLayer, passed_fog: TileMapLayer, passed_visible: TileMapLayer):
	map = passed_map
	fog = passed_fog
	player_tile = map.local_to_map(map.to_local(player.global_position))
	visible = passed_visible
	visible.clear()
	# Set player's tile to be light
	light(player_tile)
	# For each octant, run a scan
	for octant in range(8):
		scan(player_tile, octant)
	# scan(player_tile, 0)

# Scans the designated octant
func scan(start_tile: Vector2i, octant: int, radius: float = 12.5, start_col:int = 1, start_slope: float = 1.0, end_slope: float = 0.0) -> void:
	## Whether the previous tile was blocked
	var prev_blocked: bool = false
	## Saves the previous right slope of the tile for use in cases where a blocked tile transitions
	## to an empty one and it can be used instead of calculating the left slope of the empty one
	var saved_end_slope: float
	## Set transforms for octant local to map coords based on the octant being scanned
	var octant_transform: Vector4i
	match octant:
		0:
			octant_transform = Vector4i(1,0,0,1)
		1:
			octant_transform = Vector4i(0,1,1,0)
		2:
			octant_transform = Vector4i(0,-1,1,0)
		3:
			octant_transform = Vector4i(-1,0,0,1)
		4:
			octant_transform = Vector4i(-1,0,0,-1)
		5:
			octant_transform = Vector4i(0,-1,-1,0)
		6:
			octant_transform = Vector4i(0,1,-1,0)
		7:
			octant_transform = Vector4i(1,0,0,-1)

	# Perform the scan out to "range"
	for xc in range(start_col, ceili(radius)):
		# Perform scan down the line, outside to in
		for yc in range(ceili(radius), -1, -1):
			# Translate local coords to map ones
			var head_tile: Vector2i = start_tile
			head_tile.x += xc * octant_transform.x + yc * octant_transform.y
			head_tile.y -= xc * octant_transform.z + yc * octant_transform.w

			# Find the slopes to the corners of the current tile
			var tile_start_slope: float = (yc + .5) / (xc - .5)
			var tile_end_slope: float = (yc - .5) / (xc + .5)

			# If the slopes place the block to the left of the start_slope, skip it
			# if it's to the right of the end slope, we're done with the line
			if tile_end_slope >= start_slope:
				continue
			elif tile_start_slope <= end_slope:
				break

			# If the tile is between the start and end slopes, check is it's within
			# the radius of the player, if so light it
			if (xc*xc + yc*yc) < (radius * radius):
				light(head_tile)

			# Check if the tile is occupied
			var tile_blocked:bool = false
			if map.get_cell_source_id(head_tile) >= 0 && map.get_cell_tile_data(head_tile).get_custom_data("Occlude"):
				print("blocked")
				tile_blocked = true

			if prev_blocked:
				# If still along a wall, save the slope
				if tile_blocked:
					saved_end_slope = tile_end_slope
				# If no longer a wall, unset prev_blocked and set the main start slope
				# to the slope of the right edge of the previous block
				else:
					prev_blocked = false
					start_slope = saved_end_slope
			else:
				# If finding a new wall recursively scan with the left-most corner of
				# the found wall providing the end_slope
				if tile_blocked:
					# If it's the first block in the column, the slope of the top-left
					# corner will be > the initial start_slope. Instead, start 1 column
					# further
					if (tile_start_slope <= start_slope):
						scan(start_tile, octant, radius, xc+1, start_slope, tile_start_slope)
					# Keep looking down the column
					prev_blocked = true
					saved_end_slope = tile_end_slope
		# If after reaching the end of a column without finding an opening, stop
		if prev_blocked:
			break
