 # ---------->>>
 # @Author: 文雨
 # @Date: 2023-12-27 22:12:20
 # @LastEditTime: 2023-12-31 14:34:19
 # @Description: 演示场景
 # ---------->>>

extends Node2D
class_name DemoScene

@onready var fps_label :Label = $"CanvasLayer/Background/Mc/Vbc/FpsLabel"

# 主地图噪声
@export var main_noise : FastNoiseLite
# 树木噪声
@export var tree_noise : FastNoiseLite

@export var tile_set : TileSet

# 区块节点
@export var block_node : PackedScene
# 区块大小
@export var block_size : Vector2i

# 区块的父节点
@export var block_parent : Node2D

# 玩家
@export var player : Player

# 已加载的区块
var blocks :Array[Vector2i] = []
# 当前区块坐标
var current_block_coords : Vector2i

# 加载范围半径
@export var load_range_radius := 1

# 加载位置
var load_position : Vector2

# 在场景中的区块节点
var scene_block_nodes := {}

var terrain_system : SimpleTerrainSystem

func _ready() -> void:

    randomize()

    terrain_system = SimpleTerrainSystem.new(tile_set)

    main_noise.seed = randi()
    tree_noise.seed = randi()

    generate_block()

func _process(_delta: float) -> void:
    
    fps_label.text = "FPS:"+str(Engine.get_frames_per_second())

    load_position = player.position
    update_block_coords()

# 更新区块坐标
func update_block_coords() -> void:
    
    # 区块坐标
    var block_coords := tile_to_block(to_tile(load_position))

    # 如果区块坐标发生改变就更新
    if current_block_coords!=block_coords:
        current_block_coords = block_coords
        generate_block()

# 生成区块
func generate_block() -> void:

    var start_coords := current_block_coords - Vector2i(load_range_radius,load_range_radius)
    var end_coords := current_block_coords + Vector2i(load_range_radius,load_range_radius) + Vector2i.ONE

    # 基于当前坐标的所有区块坐标
    var array :Array[Vector2i] = []

    for x:int in range(start_coords.x,end_coords.x):
        for y:int in range(start_coords.y,end_coords.y):
            array.append(Vector2i(x,y))

    # 将不需要的区块卸载
    var removes :Array[Vector2i] = []

    for coords:Vector2i in blocks:
        if not array.has(coords):
            removes.append(coords)
            remove_block_node(coords)

    # 移除
    for coords:Vector2i in removes:
        blocks.erase(coords)

    # 加载
    for coords:Vector2i in array:
        if not blocks.has(coords):
            blocks.append(coords)
            add_block_node(coords)

# 添加区块节点
func add_block_node(coords: Vector2i) -> void:

    assert(not scene_block_nodes.has(coords), "要添加的区块节点已经存在！")

    var block :BlockNode = block_node.instantiate()

    block.block_coords = coords
    block.demo_scene = self
    block.position = block_to_tile(tile_to_global(coords))

    block_parent.add_child(block)
    scene_block_nodes[coords] = block

# 移除区块节点
func remove_block_node(coords: Vector2i) -> void:

    if scene_block_nodes.has(coords):
        var block :BlockNode = scene_block_nodes[coords]
        block.exit_block()
        scene_block_nodes.erase(coords)

# 获取图块大小
func get_tile_size() -> Vector2i:
    return tile_set.tile_size

# 获取区块大小
func get_block_size() -> Vector2i:
    return block_size

# 将全局坐标转换为图块坐标
func to_tile(global:Vector2) -> Vector2i:
    var vec := (global/Vector2(get_tile_size())).floor()
    return Vector2i(vec)

# 将图块坐标转换为区块坐标
func tile_to_block(tile:Vector2i) -> Vector2i:
    var vec := Vector2(tile)/Vector2(get_block_size())
    return Vector2i(vec.floor())

# 将图块坐标转换为全局坐标
func tile_to_global(tile:Vector2i) -> Vector2:
    return Vector2(tile)*Vector2(get_tile_size())

# 将区块坐标转换为图块坐标
func block_to_tile(block:Vector2i) -> Vector2i:
    return block * get_block_size()
