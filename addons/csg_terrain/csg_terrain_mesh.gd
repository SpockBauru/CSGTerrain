# Class responsible to deal with the mesh itself.
class_name CSGTerrainMesh

# Vertex grid in [x][z] plane
var vertex_grid: Array = []

var uvs: PackedVector2Array = []
var indices: PackedInt32Array = []


# Main update manager
func update_mesh(mesh: ArrayMesh, path_list: Array[CSGTerrainPath], divs: int, size: float) -> void:
	# Recrieate all mesh arrays. seems expensive but is the last of our problems.
	create_mesh_arrays(divs, size)
	
	# Make the mesh follow each path, in tree order. 90% of the time is spent here.
	for path in path_list:
		if path.curve.bake_interval != size / divs:
			path.curve.bake_interval = size / divs
		follow_curve(path, divs, size)
	
	# Organize all the mesh at once. Again, seems expensive but is not an issue.
	commit_mesh(divs, mesh)


func create_mesh_arrays(divs: int, size: float) -> void:
	# Vertex Grid follow the pattern [x][z]. The y axis is what will follow the curves
	vertex_grid.clear()
	vertex_grid.resize(divs + 1)
	
	# apply scale
	var step: float = size / divs
	var center: Vector3 = Vector3(0.5 * size, 0, 0.5 * size)
	for x in range(divs + 1):
		var vertices_z: PackedVector3Array = []
		vertices_z.resize(divs + 1)
		for z in range(divs + 1):
			vertices_z[z] = Vector3(x * step, 0, z * step) - center
		vertex_grid[x] = vertices_z
	
	# Make uvs
	uvs.clear()
	uvs.resize((divs + 1) * (divs + 1))
	var uv_step: float = 1.0 / divs
	var index: int = 0
	for x in range(divs + 1):
		for z in range(divs + 1):
			uvs[index] = Vector2(x * uv_step, z * uv_step)
			index += 1
	
	# Make quads with two triangles
	indices.clear()
	indices.resize(divs * divs * 6)
	var row: int = 0
	var next_row: int = 0
	index = 0
	for x in range(divs):
		row = next_row
		next_row += divs + 1
		
		# Making the two triangles. Ways to make more readable are welcomed.
		for z in range(divs):
			# First triangle vertices
			indices[index] = z + row
			index += 1
			indices[index] = z + next_row + 1
			index += 1
			indices[index] = z + row + 1
			index += 1
			# Second triangle vertices
			indices[index] = z + row
			index += 1
			indices[index] = z + next_row
			index += 1
			indices[index] = z + next_row + 1
			index += 1


func commit_mesh(divs: int, mesh: ArrayMesh) -> void:
	# Mesh in ArrayMesh format
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_TEX_UV2] = uvs
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	# Organize vertex matrix in format PackedVector3Array
	var vert_list: PackedVector3Array = []
	for array in vertex_grid:
		vert_list.append_array(array)
	
	surface_array[Mesh.ARRAY_VERTEX] = vert_list
	
	# Make normals according Clever Normalization of a Mesh: https://iquilezles.org/articles/normals/
	# Making manually because using surfacetool was 3-5 times slower
	var normals: PackedVector3Array = []
	normals.resize((divs + 1) * (divs + 1))
	var index: int = 0
	for i in range(indices.size() / 3):
		# Vertices of the triangle
		var a: Vector3 = vert_list[indices[index]]
		index += 1
		var b: Vector3 = vert_list[indices[index]]
		index += 1
		var c: Vector3 = vert_list[indices[index]]
		index += 1
		
		# Creating normal from edges
		var edge1: Vector3 = b - a
		var edge2: Vector3 = c - a
		var normal: Vector3 = edge1.cross(edge2)
		
		# Adding normal to each vertex
		normals[indices[index - 1]] += normal
		normals[indices[index - 2]] += normal
		normals[indices[index - 3]] += normal
	
	# Normalize and apply
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
	
	surface_array[Mesh.ARRAY_NORMAL] = normals
	
	#Commit to the main mash
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)


func follow_curve(path: CSGTerrainPath, divs: int, size: float) -> void:
	var width: int = path.width
	var smoothness: float = path.smoothness
	
	var pos: Vector3 = path.position
	var center: Vector3 = Vector3(0.5 * size, 0, 0.5 * size)
	var curve: Curve3D = path.curve
	var baked3D: PackedVector3Array = curve.get_baked_points()
	
	if baked3D.size() < 2: return
	
	# Make a curve on xz plane
	var baked2D: Array[Vector2] = []
	baked2D.resize(baked3D.size())
	for i in range(baked3D.size()):
		var point: Vector3 = baked3D[i]
		baked2D[i] = Vector2(point.x, point.z)
	
	# Dictionary with vertices around the curve by "witdh" size
	var curve_vertices = {}
	for point in baked3D:
		var local_point: Vector3 = point + pos + center
		
		# Point in the vertex_grid
		var grid_point: Vector3 = local_point * divs / size
		var grid_index: Vector2i = Vector2i(int(grid_point.x), int(grid_point.z))
		
		# Exprore the region around the point. Cut out points outside the grid
		var range_min_x: int = -width + 1 + grid_index.x
		range_min_x = clampi(range_min_x, 0, divs + 1)
		var range_max_x: int = width + 2 + grid_index.x
		range_max_x = clampi(range_max_x, 0, divs + 1)
		var range_min_y: int = -width + 1 + grid_index.y
		range_min_y = clampi(range_min_y, 0, divs + 1)
		var range_max_y: int = width + 2 + grid_index.y
		range_max_y = clampi(range_max_y, 0, divs + 1)
		
		for i in range(range_min_x, range_max_x):
			for j in range(range_min_y, range_max_y):
				curve_vertices[Vector2i(i, j)] = true
	
	# Interpolate the height of the vertices
	for grid_idx in curve_vertices:
		var vertex: Vector3 = vertex_grid[grid_idx.x][grid_idx.y]
		var old_vertex: Vector3 = vertex
		
		# Vertex in path space
		var path_vertex: Vector3 = vertex - pos
		var closest: Vector3 = get_closest_point_in_xz_plane(baked2D, baked3D, path_vertex)
		
		# Back to local space
		closest += pos
		
		# Distance relative to path witdh.
		vertex.y = closest.y
		var dist = vertex.distance_to(closest)
		if width == 0: width = 1
		var dist_relative: float = (dist * divs) / (width * size)
		
		# Quadratic smooth
		var lerp_weight: float = dist_relative * dist_relative * smoothness
		lerp_weight = clampf(lerp_weight, 0, 1)
		var height: float = lerpf(closest.y, old_vertex.y, lerp_weight)
		vertex.y = height
		
		vertex_grid[grid_idx.x][grid_idx.y] = vertex
	
	# Update indices on affected vertices
	for grid_idx in curve_vertices:
		update_quad_indices(grid_idx, divs)

# Get the closest point on the 3D curve given a point on the xz plane. Really expensive, takes 80% of all time!
func get_closest_point_in_xz_plane(points_2D: Array[Vector2], points_3D: Array[Vector3], vertex3D: Vector3) -> Vector3:
	var vertex2D = Vector2(vertex3D.x, vertex3D.z)
	var closest2D: Vector2 = Vector2.ZERO
	
	# Get the closest point in xz plane
	var min_dist: float = INF
	var min_idx: int = 0
	for i in range(points_2D.size() - 1):
		var point2D: Vector2 = points_2D[i]
		var next_point2D: Vector2 = points_2D[i + 1]
		
		# The reason why this methos is so expensive, this function is made by brute force on Godot code!
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(vertex2D, point2D, next_point2D)
		var dist = closest.distance_squared_to(vertex2D)
		
		if dist < min_dist:
			min_dist = dist
			min_idx = i
			closest2D = closest
	
	# Get the point in the 3D curve
	var point3D: Vector3 = points_3D[min_idx]
	var next_point3D: Vector3 = points_3D[min_idx + 1]
	var close3D: PackedVector3Array = Geometry3D.get_closest_points_between_segments(
		point3D, next_point3D,
		# Vertical axis that cross the curve
		Vector3(closest2D.x, -65536, closest2D.y), Vector3(closest2D.x, 65536, closest2D.y))
	
	var closest_point: Vector3 = close3D[0]
	return closest_point


# There are two ways to triangularize a quad. To better follow the path, convex in y will be used
func update_quad_indices(idx: Vector2i, divs: int) -> void:
	var x: int = idx.x
	if (x + 1) > divs: return
	var z: int = idx.y
	if (z + 1) > divs: return
	# Make faces with two triangles
	var row: int = x * (divs + 1)
	var next_row: int = row + divs + 1
	var index: int = 6 * (x * divs + z)
	 
	# There are two ways to triangularize a quad. Each one with one diagonal.
	# Getting the middle point of each diagonal
	var diagonal_1: Vector3 = 0.5 * (vertex_grid[x][z] + vertex_grid[x + 1][z + 1])
	var diagonal_2: Vector3 = 0.5 * (vertex_grid[x + 1][z] + vertex_grid[x][z + 1])
	
	# The diagonal with the upper middle point will be convex in y
	if diagonal_1.y >= diagonal_2.y:
		# First triangle vertices
		indices[index] = z + row
		index += 1
		indices[index] = z + next_row + 1
		index += 1
		indices[index] = z + row + 1
		index += 1
		# Second triangle vertices
		indices[index] = z + row
		index += 1
		indices[index] = z + next_row
		index += 1
		indices[index] = z + next_row + 1
	else:
		# First triangle vertices
		indices[index] = z + next_row
		index += 1
		indices[index] = z + next_row + 1
		index += 1
		indices[index] = z + row + 1
		index += 1
		## Second triangle vertices
		indices[index] = z + next_row
		index += 1
		indices[index] = z + row + 1
		index += 1
		indices[index] = z + row