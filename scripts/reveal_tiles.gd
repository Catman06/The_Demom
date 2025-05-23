class_name RevealTiles
extends RayCast2D

var angle_count: int = 512

func reveal(ray: RayCast2D, map: TileMapLayer, fog: TileMapLayer) -> void:
	# Reset the ray's target position to avoid it drifting
	ray.target_position = Vector2(0,200)
	# For each of "angles" angles, cast a ray to remove fog
	for angle in range(0,angle_count):
		ray.target_position = ray.target_position.rotated((PI*2/angle_count) * angle)
		cast(ray,map,fog)

# Cast the ray
func cast(ray: RayCast2D, map: TileMapLayer, fog: TileMapLayer) -> void:
	ray.force_raycast_update()
	if !ray.is_colliding():
		return
	## The collided with tile
	var collision_tile: Vector2i = map.local_to_map(map.to_local(ray.get_collision_point() + (ray.target_position.normalized())))
	## The TileData for the collided tile
	var collision_tiledata: TileData = map.get_cell_tile_data(collision_tile)
	# Erase the fog from the tile that was collided
	fog.erase_cell(collision_tile)
	# If the collided tile isn't exit, because something has gone wrong
	if collision_tiledata == null:
		return
	# If the collided tile isn't a wall keep scanning through until you find one, and go a bit more to find walls at shallow angles
	if !collision_tiledata.get_custom_data("Occlude"):
		## The point 1 further along the path of the ray
		var next_point = ray.get_collision_point() + (ray.target_position.normalized())
		## Whether a wall has been reached
		var stop: bool = false
		## How many scans further to go once finding a wall
		var stop_dist = 10
		while true:
			## The tile that "next_point" is in
			var next_tile = map.local_to_map(map.to_local(next_point))
			# For these, always check for null before getting custom data to avoid crashes
			# If a tile isn't null and is a wall, set stop
			if !map.get_cell_tile_data(next_tile) == null && map.get_cell_tile_data(next_tile).get_custom_data("Occlude"):
				fog.erase_cell(map.local_to_map(map.to_local(next_point)))
				next_point += (ray.target_position.normalized() * 2)
				stop = true
			# If the tile is null, just keep scanning, unless stop is set, in which case immediately break
			elif map.get_cell_tile_data(next_tile) == null:
				next_point += (ray.target_position.normalized() * 2)
			# If the tile isn't null, and isn't a wall, erase any fog on the tile, and keep scanning, unless stop is set, in which case immediately break
			elif !map.get_cell_tile_data(next_tile) == null && !map.get_cell_tile_data(next_tile).get_custom_data("Occlude"):
				if stop:
					break
				if !fog.get_cell_tile_data(next_tile) == null:
					fog.erase_cell(next_tile)
				next_point += (ray.target_position.normalized() * 2)
			if stop:
				stop_dist -= 1
				if stop_dist == 0:
					break
			
