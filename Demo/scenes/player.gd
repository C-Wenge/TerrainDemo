 # ---------->>>
 # @Author: 文雨
 # @Date: 2023-12-27 23:11:59
 # @LastEditTime: 2023-12-27 23:53:11
 # @Description: 玩家
 # ---------->>>

extends CharacterBody2D
class_name Player

# 移动速度
@export var move_speed := 200.0

# 相机
@export var camera : Camera2D

func _input(event: InputEvent) -> void:

    if event is InputEventMouseButton:

        if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera.zoom.x = max(0.5,camera.zoom.x-0.01)

        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera.zoom.x = min(3.0,camera.zoom.x+0.01)

        camera.zoom.y = camera.zoom.x

func _physics_process(_delta: float) -> void:

    var vec := Input.get_vector("move_left","move_right","move_up","move_down")
    velocity = vec * move_speed
    move_and_slide()