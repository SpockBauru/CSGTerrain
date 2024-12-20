# WARNING: This is early code still in development, do NOT use in any project

# CSG Terrain
> ### Prototype your terrain faster with the power of curves and [CSG nodes](https://docs.godotengine.org/en/stable/tutorials/3d/csg_tools.html)


## What is it?
This is a plugin for Godot Engine to prototype terrains on a simple and not destructive way. It's made with CSG (Constructive Solid Geometry), so you are supposed to combine with geometric shapes and even other terrains to achieve the desired form. [Read more about CSG](https://docs.godotengine.org/en/stable/tutorials/3d/csg_tools.html)

Unlike other systems **the terrain is molded purely with paths, not brushes or other 3D tools**. This forced simplicity allows to focus on what is important before finalizing in 3D software.


## How does it work?
When placing a CSGTerrain node, it will also place a Path3D in the middle and the terrain will follow it. 

This is the basic idea: You place paths, and the terrain follows.

You can place as many Path3D nodes as needed.


## The Path workflow
The terrain follows the line between the points of the path. Because of that each path needs at least 2 points to work. 

When creating a new Path3D as child of the CSG Terrain node, the path node will contain various extra parameters:

**Width:** The number of terrain vertices affected on each side of the curve. The value 2 will affect 2 vertices on each side, the number 0 will only affect the closest vertex.

**Smoothness:** Amount of curvature around the path. Value 1 will smoothly lower the curve. Zero will create a flat slope with the height of the curve.

**Path Texture:** Enabling this option a texture will be drown on the terrain right bellow the curve. You can choose the texture in the [Terrain Material](#terrain-material)

**Texture Width:** How many pixels around the path that will be painted.

**Texture Smoothness:** How much the path texture will blend with the terrain. Zero will cause blockness and high values will make the texture thinner.


### Order matters
Similar to canvas items, paths that are childs of the CSG Terrain node will be applied one on top of each other following the order in the scene tree.

The first child will be drown on bottom and the last will be drown on top. 

You can change the order at will.


## The CSGTerrain node
The CSGTerrain node comes with several parameters:

**Size:** The size of each side of the terrain. Terrains will always be squared. Smaller terrains will have higher vertex density and vice versa.

**Divs:** The number of faces on each side of the terrain. Higher values will cause slowdown and are not recommended. Place several smaller terrains instead.

**Path Mask Resolution:** The resolution of the mask applied to the path texture. Only change if the path texture is not merging accordingly.


## The Terrain material
The terrain material is located on the CSG node, in CSGMesh section.

It's composed of 3 materials: Ground, Walls and Path

For each one you can change the material properties and the textures for Albedo, Normal Map and Roughness Map (Rough Map) similar to [Godot's StandardMaterial3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html) counterparts.

The Shader Parameter **Wall Underlay** set how the wall will be merged with the ground. Zero means no wall will be applied. High values will make the transition sharper.

The terrain material aims to be simple and serves as base for users make their own terrain material. In the final product it's recommended to polish this shader and make optimizations such as [channel packing](http://wiki.polycount.com/wiki/ChannelPacking)


## Future features and how to contribute
CSGTerrain is designed to be as simple as possible. Because of that **no new features are planned** in order to avoid [feature creep](https://en.wikipedia.org/wiki/Feature_creep). 

The code aims to be readable and beginner friendly. Users are encoraged to change and expand the code in their end, but this repository must be kept neat and tidy.

Contributions to make the code simpler, more readable and bugfixes are welcomed. Optimizations must be easy to understand even for beginner users, example: Advanced features like compute shaders would greatly benefits the plugin speed, but was kept out of the code in order to keep it accessible for beginners.
