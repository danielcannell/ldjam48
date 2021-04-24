extends KinematicBody2D


enum SwimState { IDLE, LEFT, RIGHT }
enum AttackState { IDLE, AIM, FIRE }


onready var sprite := $Sprite
onready var arrow := $Arrow


var harpoon = null
var velocity := Vector2(0, 100)
var swim_state: int = SwimState.IDLE
var attack_state: int = AttackState.IDLE


func _ready() -> void:
    pass


func set_harpoon(h) -> void:
    harpoon = h


func update_swim_state(a: Vector2) -> void:
    var new_swim_state = SwimState.IDLE
    if a.x > 100:
        new_swim_state = SwimState.RIGHT
    elif a.x < -100:
        new_swim_state = SwimState.LEFT

    if new_swim_state != swim_state:
        swim_state = new_swim_state

        match swim_state:
            SwimState.IDLE:
                sprite.set_animation("idle")
            SwimState.LEFT:
                sprite.set_animation("swim")
                sprite.set_flip_h(false)
            SwimState.RIGHT:
                sprite.set_animation("swim")
                sprite.set_flip_h(true)


func update_attack_state() -> void:
    match attack_state:
        AttackState.IDLE:
            if Input.is_action_pressed("attack"):
                arrow.visible = true
                attack_state = AttackState.AIM

        AttackState.AIM:
            if !Input.is_action_pressed("attack"):
                arrow.visible = false
                attack_state = AttackState.FIRE

                if harpoon != null:
                    harpoon.fire(position, velocity, arrow.rotation)

        AttackState.FIRE:
            pass

    if attack_state == AttackState.AIM:
        var mouse_dir := get_global_mouse_position() - position
        arrow.rotation = mouse_dir.angle()


func _process(_delta: float) -> void:
    update_attack_state()


func _physics_process(delta: float) -> void:

    var a := Vector2.ZERO

    if Input.is_action_pressed("up"):
        a.y -= 1000
    if Input.is_action_pressed("down"):
        a.y += 1000
    if Input.is_action_pressed("left"):
        a.x -= 1000
    if Input.is_action_pressed("right"):
        a.x += 1000

    # Get viewport rect in canvas coordinates
    var visible = get_viewport_transform().xform_inv(get_viewport_rect())
    var allowed = visible.grow(-100)

    if !allowed.has_point(position):
        var left_dist = position.x - allowed.position.x
        var right_dist = allowed.end.x - position.x
        var top_dist = position.y - allowed.position.y
        var bottom_dist = allowed.end.y - position.y

        if left_dist < 0:
            a.x += 10 * -left_dist
            if velocity.x < 0:
                a.x -= 5 * velocity.x

        if right_dist < 0:
            a.x -= 10 * -right_dist
            if velocity.x > 0:
                a.x -= 5 * velocity.x

        if top_dist < 0:
            a.y += 10 * -top_dist
            if velocity.y < 100:
                a.y -= 5 * (velocity.y - 100)

        if bottom_dist < 0:
            a.y -= 10 * -bottom_dist
            if velocity.y > 100:
                a.y -= 5 * (velocity.y - 100)

    update_swim_state(a)

    # Damping
    a -= velocity - Vector2(0, 200)

    velocity += delta * a
    move_and_slide(velocity)

    Globals.player_position = position
