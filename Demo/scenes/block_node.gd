 # ---------->>>
 # @Author: 文雨
 # @Date: 2023-12-27 22:49:38
 # @LastEditTime: 2023-12-31 14:42:21
 # @Description: 地图区块节点
 # ---------->>>

extends Node2D
class_name BlockNode

# 演示场景
var demo_scene : DemoScene

# 水图块
var water_tile : TerrainTile
# 草图块
var grass_tiles := []
# 树图块
var tree_tiles := []

# 区块坐标
var block_coords : Vector2i
# 开始图块坐标
var start_tile_coords : Vector2i
# 区块大小
var block_size : Vector2i

# 线程任务id
var task_id : int
# 是否退出
var block_exit := false

func _ready() -> void:

    init_tile()

    start_tile_coords = demo_scene.block_to_tile(block_coords)
    block_size = demo_scene.get_block_size()

    task_id = WorkerThreadPool.add_task(thread_generate,true)

func init_tile() -> void:

    # 水的图块
    water_tile = TerrainTile.new()
    water_tile.source_id = 0
    water_tile.atlas_coords = Vector2i(0,0)
    water_tile.alternative_tile = 0

    var grass1 := TerrainTile.new()
    grass1.source_id = 1
    grass1.atlas_coords = Vector2i.ZERO
    grass1.alternative_tile = 0

    grass_tiles.append(grass1)

    var grass2 := TerrainTile.new()
    grass2.source_id = 1
    grass2.atlas_coords = Vector2i(1,0)
    grass2.alternative_tile = 0

    grass_tiles.append(grass2)

    var grass3 := TerrainTile.new()
    grass3.source_id = 1
    grass3.atlas_coords = Vector2i(2,0)
    grass3.alternative_tile = 0

    grass_tiles.append(grass3)

    var tree1 := TerrainTile.new()
    tree1.source_id = 3
    tree1.atlas_coords =Vector2i.ZERO
    tree1.alternative_tile = 0

    tree_tiles.append(tree1)

    var tree2 := TerrainTile.new()
    tree2.source_id = 4
    tree2.atlas_coords =Vector2i.ZERO
    tree2.alternative_tile = 0

    tree_tiles.append(tree2)

func _process(_delta: float) -> void:

    if block_exit and WorkerThreadPool.is_task_completed(task_id) and not is_queued_for_deletion():
        queue_free()

# 使用线程生成地图数据，注意线程安全
func thread_generate() -> void:

    var all_coords := []

    var water_layer := {}
    var soil_layer := {}
    var grassland1_layer := {}
    var grass_layer := {}

    for x : int in range(-1,block_size.x+1):
        for y : int in range(-1,block_size.y+1):

            var coords := Vector2i(x,y)
            var noise_coords := coords + start_tile_coords

            all_coords.append(coords)

            # 按照不同的噪声值绘制不同的地形
            var main_value :float = demo_scene.main_noise.get_noise_2dv(noise_coords)

            if main_value < 0.0:
                water_layer[coords] = water_tile

            if main_value >= 0.0 and main_value<0.3:
                demo_scene.terrain_system.draw_terrain(soil_layer,coords,0)

            if main_value >= 0.1:
                demo_scene.terrain_system.draw_terrain(grassland1_layer,coords,1)

                if main_value >= 0.2:

                    var tree_value := demo_scene.tree_noise.get_noise_2dv(coords)
                    if tree_value<=0.2 and randf() < 0.03:
                        var tree_tile :TerrainTile = tree_tiles[randi()%tree_tiles.size()]
                        grass_layer[coords] = tree_tile
                    elif randf() < 0.3:
                        var tile :TerrainTile = grass_tiles[randi()%grass_tiles.size()]
                        grass_layer[coords] = tile

    
    # 转化为TileMap使用的tile data
    var tile_datas :Array[PackedInt32Array] = [
        PackedInt32Array(),
        PackedInt32Array(),
        PackedInt32Array(),
        PackedInt32Array()
    ]

    for coords : Vector2i in all_coords:

        if coords.x<0 or coords.x>=block_size.x or \
            coords.y<0 or coords.y>=block_size.y:
            continue

        if water_layer.has(coords):
            var tile :TerrainTile = water_layer[coords]
            add_tile_data(tile_datas[0],coords,tile)

        if soil_layer.has(coords):
            var tile :TerrainTile = soil_layer[coords]
            add_tile_data(tile_datas[1],coords,tile)

        if grassland1_layer.has(coords):
            var tile :TerrainTile = grassland1_layer[coords]
            add_tile_data(tile_datas[2],coords,tile)

        if grass_layer.has(coords):
            var tile :TerrainTile = grass_layer[coords]
            add_tile_data(tile_datas[3],coords,tile)

    # 生成完成，下一帧由主线程将tile data传递给TileMap
    call_deferred("generate_finish",tile_datas)


func add_tile_data(array: PackedInt32Array, coords: Vector2i, tile: TerrainTile) -> void:

    array.append_array(demo_scene.terrain_system.to_tile_data(
        coords,
        tile.source_id,
        tile.atlas_coords,
        tile.alternative_tile,
        false,false,false
        ))

# 由主线程设置TileMap的tile data
func generate_finish(tile_datas: Array[PackedInt32Array]) -> void:

    for layer : int in tile_datas.size():
        var tile_data :PackedInt32Array = tile_datas[layer]
        set("layer_"+str(layer)+"/tile_data",tile_data)

# 退出
func exit_block() -> void:
    block_exit = true
