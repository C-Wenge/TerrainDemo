 # ---------->>>
 # @Author: 文雨
 # @Date: 2023-12-27 01:47:49
 # @LastEditTime: 2023-12-27 05:24:46
 # @Description: 地形图块
 # ---------->>>

extends RefCounted
class_name TerrainTile

var source_id : int
var atlas_coords : Vector2i
var alternative_tile : int

# 所属地形
var terrain : int

# 位右
var bit_right := false
# 位右下
var bit_right_down := false
# 位下
var bit_down := false
# 位左下
var bit_left_down := false
# 位左
var bit_left := false
# 位左上
var bit_left_up := false
# 位上
var bit_up := false
# 位右上
var bit_right_up := false

# 设置指定方向的位
func set_direction_bit(dir: Vector2i, value: bool) -> void:

    match dir:
        Vector2i.RIGHT:
            bit_right = value
        Vector2i(1,1):
            bit_right_down = value
        Vector2i.DOWN:
            bit_down = value
        Vector2i(-1,1):
            bit_left_down = value
        Vector2i.LEFT:
            bit_left = value
        Vector2i(-1,-1):
            bit_left_up = value
        Vector2i.UP:
            bit_up = value
        Vector2i(1,-1):
            bit_right_up = value
        _:
            push_warning("不存在方向%s"%dir)

# 获取这个图块副本
func duplicate() -> TerrainTile:

    var terrain_tile := TerrainTile.new()

    terrain_tile.source_id = source_id
    terrain_tile.atlas_coords = atlas_coords
    terrain_tile.alternative_tile = alternative_tile

    terrain_tile.terrain = terrain

    terrain_tile.bit_right = bit_right
    terrain_tile.bit_right_down = bit_right_down
    terrain_tile.bit_down = bit_down
    terrain_tile.bit_left_down = bit_left_down
    terrain_tile.bit_left = bit_left
    terrain_tile.bit_left_up = bit_left_up
    terrain_tile.bit_up = bit_up
    terrain_tile.bit_right_up = bit_right_up

    return terrain_tile

func _to_string() -> String:

    return "地形:"+str(terrain)+\
    "右:"+str(bit_right)+\
    "右下:"+str(bit_right_down)+\
    "下:"+str(bit_down)+\
    "左下:"+str(bit_left_down)+\
    "左:"+str(bit_left)+\
    "左上:"+str(bit_left_up)+\
    "上:"+str(bit_up)+\
    "右上:"+str(bit_right_up)