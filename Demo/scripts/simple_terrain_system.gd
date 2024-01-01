 # ---------->>>
 # @Author: 文雨
 # @Date: 2023-12-27 01:41:31
 # @LastEditTime: 2023-12-31 13:17:11
 # @Description: 简单的地形系统，仅支持3x3的单一地形匹配
 # ---------->>>

extends RefCounted
class_name SimpleTerrainSystem

# 八个方向的向量
const DIRECTIONS := [
    Vector2i.RIGHT,
    Vector2i(1,1),
    Vector2i.DOWN,
    Vector2i(-1,1),
    Vector2i.LEFT,
    Vector2i(-1,-1),
    Vector2i.UP,
    Vector2i(1,-1)
]


# 所有地形图块
var terrain_tiles := {}

# 构建需要一个TileSet
func _init(tile_set: TileSet) -> void:

    for i : int in tile_set.get_source_count():

        var source_id :int = tile_set.get_source_id(i)

        if not tile_set.get_source(source_id) is TileSetAtlasSource:
            continue

        var source :TileSetAtlasSource = tile_set.get_source(source_id)

        _handle_source(source,source_id)

func _handle_source(source: TileSetAtlasSource,source_id: int) -> void:

    for j : int in source.get_tiles_count():

        var atlas_coords :Vector2i = source.get_tile_id(j)
        for k : int in source.get_alternative_tiles_count(atlas_coords):
            
            var alternative_tile :int = source.get_alternative_tile_id(atlas_coords,k)

            var tile_data :TileData = source.get_tile_data(atlas_coords,alternative_tile)

            # 目前仅支持一个地形集
            if tile_data.terrain_set>0:
                push_warning("地形集%s将被忽略，仅支持第一个地形集"% tile_data.terrain_set)
                continue

            if tile_data.terrain < 0:
                continue

            var terrain_tile := TerrainTile.new()
            terrain_tile.source_id = source_id
            terrain_tile.atlas_coords = atlas_coords
            terrain_tile.alternative_tile = alternative_tile

            terrain_tile.terrain = tile_data.terrain

            terrain_tile.bit_right = tile_data.get_terrain_peering_bit(
                TileSet.CELL_NEIGHBOR_RIGHT_SIDE) == terrain_tile.terrain

            terrain_tile.bit_right_down = tile_data.get_terrain_peering_bit(
                TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER) == terrain_tile.terrain

            terrain_tile.bit_down = tile_data.get_terrain_peering_bit(
                TileSet.CELL_NEIGHBOR_BOTTOM_SIDE) == terrain_tile.terrain

            terrain_tile.bit_left_down = tile_data.get_terrain_peering_bit(
                TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER) == terrain_tile.terrain

            terrain_tile.bit_left = tile_data.get_terrain_peering_bit(
                TileSet.CELL_NEIGHBOR_LEFT_SIDE) == terrain_tile.terrain

            terrain_tile.bit_left_up = tile_data.get_terrain_peering_bit(
                TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER) == terrain_tile.terrain

            terrain_tile.bit_up = tile_data.get_terrain_peering_bit(
                TileSet.CELL_NEIGHBOR_TOP_SIDE) == terrain_tile.terrain

            terrain_tile.bit_right_up = tile_data.get_terrain_peering_bit(
                TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER) == terrain_tile.terrain

            add_terrain_tile(terrain_tile)

# 添加一个地形图块
func add_terrain_tile(tile: TerrainTile) -> void:
    
    var tiles :Dictionary = terrain_tiles[tile.terrain] \
    if terrain_tiles.has(tile.terrain) else {}

    var id := get_terrain_tile_id(tile)
    tiles[id] = tile

    if not terrain_tiles.has(tile.terrain):
        terrain_tiles[tile.terrain] = tiles

# 获取一个地形图块，如果没有就返回null
func get_terrain_tile(terrain: int, id: int) -> TerrainTile:

    var tiles :Dictionary = terrain_tiles[terrain] \
    if terrain_tiles.has(terrain) else {}

    if tiles.has(id):
        return tiles[id].duplicate()

    return null

# 获取地形图块的id
func get_terrain_tile_id(tile: TerrainTile) -> int:
    
    var id :int = (0 | int(tile.bit_right)) << 1
    id = (id | int(tile.bit_right_down)) << 1
    id = (id | int(tile.bit_down)) << 1
    id = (id | int(tile.bit_left_down)) << 1
    id = (id | int(tile.bit_left)) << 1
    id = (id | int(tile.bit_left_up)) << 1
    id = (id | int(tile.bit_up)) << 1
    id = (id | int(tile.bit_right_up)) << 7

    return id

# 转换为TileMap使用的tile data
func to_tile_data(coords:Vector2i, source_id:int, atlas_coords:Vector2i,
    alternative_tile:int,transpose:bool, flip_v:bool, flip_h:bool) -> PackedInt32Array:

    var array := PackedInt32Array()

    # 第1位32位整数前16位表示坐标的y，后16位表示坐标x
    var coords_32 :int = int(coords.y) << 16 | int(coords.x)
    array.append(coords_32)

    # 第2位32位整数前16位表示图集坐标的x，后16位表示源id
    var atlas_source_32 :int = int(atlas_coords.x) << 16 | int(source_id)
    array.append(atlas_source_32)

    # 第3位32位整数的第1位是0，因为这是一个整数，如果转置是true第2位是1否则位0
    var int_32 :int = (1 if transpose else 0) << 1
    # 如果垂直翻转为true则第3位为1否则为0
    int_32 = (int_32 | (1 if flip_v else 0)) << 1
    # 如果水平翻转为true则第4位为1否则为0
    int_32 = (int_32 | (1 if flip_h else 0)) << 28
    # 后12位表示备选
    int_32 = int_32 | (alternative_tile << 16)
    # 最后的16位是图集坐标y
    int_32 = int_32 | int(atlas_coords.y)

    array.append(int_32)

    return array

# 标准化地形图块
func norm_terrain_tile(terrain_tile: TerrainTile) -> TerrainTile:

    if terrain_tile.bit_right_down:
        terrain_tile.bit_right_down = terrain_tile.bit_right and terrain_tile.bit_down
    if terrain_tile.bit_right_up:
        terrain_tile.bit_right_up = terrain_tile.bit_right and terrain_tile.bit_up
    if terrain_tile.bit_left_down:
        terrain_tile.bit_left_down = terrain_tile.bit_left and terrain_tile.bit_down
    if terrain_tile.bit_left_up:
        terrain_tile.bit_left_up = terrain_tile.bit_left and terrain_tile.bit_up

    return terrain_tile

# 绘制地形
func draw_terrain(map_dict: Dictionary, coords: Vector2i, terrain: int) -> void:

    var terrain_tile := TerrainTile.new()
    terrain_tile.terrain = terrain

    var update_coords := []

    for dir : Vector2i in DIRECTIONS:

        var neighbour := coords + dir

        if map_dict.has(neighbour):

            var tile :TerrainTile = map_dict[neighbour]
            if tile.terrain == terrain:

                terrain_tile.set_direction_bit(dir,true)
                update_coords.append(neighbour)

    terrain_tile = norm_terrain_tile(terrain_tile)

    var id := get_terrain_tile_id(terrain_tile)

    var target_tile := get_terrain_tile(terrain,id)

    if not is_instance_valid(target_tile):
        print(terrain_tile)
    else :
        map_dict[coords] = target_tile

    for u_coords : Vector2i in update_coords:
        update_terrain(map_dict,u_coords)

# 更新地形
func update_terrain(map_dict: Dictionary, coords: Vector2i) -> void:
    
    if not map_dict.has(coords):
        return

    var terrain_tile :TerrainTile = map_dict[coords].duplicate()

    for dir : Vector2i in DIRECTIONS:

        var neighbour := coords + dir

        if map_dict.has(neighbour):
            var tile :TerrainTile = map_dict[neighbour]

            if tile.terrain == terrain_tile.terrain:
                terrain_tile.set_direction_bit(dir,true)

    terrain_tile = norm_terrain_tile(terrain_tile)

    var id := get_terrain_tile_id(terrain_tile)

    var target_tile := get_terrain_tile(terrain_tile.terrain,id)

    if not is_instance_valid(target_tile):
        print(terrain_tile)
        return

    map_dict[coords] = target_tile