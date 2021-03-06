﻿module abandonedtemple.demos.demo3_camera;

import std.exception : assumeUnique;
import std.traits : EnumMembers;

import gl3n.linalg;
import std.stdio;
import gl3n.math;

enum Direction {
    UP,
    DOWN,
    LEFT,
    RIGHT,
};

enum DirectionState {
    NONE,
    FIRST,
    REPEAT,
    LAST,
};

immutable float[int] lastFrameOffsets;

static this() {

    float[int] temp;
    temp[cast(int)temp.length] = 0.01f;
    temp[cast(int)temp.length] = 0.01f;
    temp[cast(int)temp.length] = 0.01f;
    temp[cast(int)temp.length] = 0.01f;
    temp[cast(int)temp.length] = 0.01f;
    temp[cast(int)temp.length] = 0.01f;
    temp[cast(int)temp.length] = 0.01f;
    temp[cast(int)temp.length] = 0.02f;
    temp[cast(int)temp.length] = 0.03f;
    temp[cast(int)temp.length] = 0.04f;
    temp[cast(int)temp.length] = 0.05f;
    temp[cast(int)temp.length] = 0.06f;
    temp[cast(int)temp.length] = 0.07f;
    temp[cast(int)temp.length] = 0.08f;
    temp[cast(int)temp.length] = 0.09f;
    temp[cast(int)temp.length] = 0.1f;

    lastFrameOffsets = assumeUnique(temp);
}

interface ICamera {
    mat4 viewMatrix();
    mat4 perspectiveMatrix();
    void update();
    void reset();
    void keyPressed(Direction k);
    void keyUnpressed(Direction k);
}

mat4 calculateFrustum(float scale, float aspect, float near, float far) {
    mat4 ret = mat4(0);
    ret[0][0] = scale / aspect;
    ret[1][1] = scale;
    ret[2][2] = (far+near)/(far-near);
    ret[2][3] = 1f;
    ret[3][2] = -(2 * far * near)/(far-near);
    return ret;
}

class Camera : ICamera {
    private {
        immutable static defaultOffset = vec3(0f, -3f, 0f);
        immutable static defaultRotation = vec3(-.4f, 0f, 0f);
        vec3 offset = defaultOffset;
        vec3 rotation = defaultRotation;
        DirectionState[Direction] directionState;
        int[Direction] lastCounter;
        mat4 _viewMatrix;
        mat4 _perspectiveMatrix;
    }

    mat4 viewMatrix() {
        return _viewMatrix;
    }

    mat4 perspectiveMatrix() {
        return _perspectiveMatrix;
    }


    this() {

        reset();
    }

    void update() {
        foreach(Direction direction; EnumMembers!Direction) {
            float direction_offset = 0f;
            final switch (directionState[direction]) {
                case DirectionState.NONE:
                    break;
                case DirectionState.FIRST:
                    direction_offset = 0.05f;
                    directionState[direction] = DirectionState.REPEAT;
                    break;
                case DirectionState.REPEAT:
                    direction_offset = 0.1f;
                    break;
                case DirectionState.LAST:
                    direction_offset = lastFrameOffsets[lastCounter[direction]];
                    lastCounter[direction]--;
                    if (lastCounter[direction] == 2) {
                        directionState[direction] = DirectionState.NONE;
                    }
                    break;
            }

            final switch (direction) {
                case Direction.UP:
                    offset.z -= direction_offset;
                    break;
                case Direction.DOWN:
                    offset.z += direction_offset;
                    break;
                case Direction.LEFT:
                    offset.x += direction_offset;
                    break;
                case Direction.RIGHT:
                    offset.x -= direction_offset;
                    break;
            }
        }

        _viewMatrix = mat4.identity
            .translate(offset.x, offset.y, offset.z)
            .rotatex(rotation.x)
            .rotatey(rotation.y)
            .rotatez(rotation.z)
            ;
    }

    void reset() {
        offset = defaultOffset;
        rotation = defaultRotation;
        foreach(Direction direction; EnumMembers!Direction) {
            directionState[direction] = DirectionState.NONE;
        }
        foreach(Direction direction; EnumMembers!Direction) {
            lastCounter[direction] = 0;
        }
    }

    void keyPressed(Direction k) {
        directionState[k] = DirectionState.FIRST;
    }

    void keyUnpressed(Direction k) {
        if (directionState[k] != DirectionState.NONE) {
            directionState[k] = DirectionState.LAST;
        }
        lastCounter[k] = cast(int)lastFrameOffsets.length - 1;
    }

}

class CityCamera : ICamera {
    private {
        immutable static defaultTarget = vec3(0f, -0.25f, 0f);
        immutable static defaultRotation = vec2(0f, 0f);
        vec3 target = defaultTarget;
        vec2 plane_rotation = defaultRotation;
        float distance = 3f;
        mat4 _viewMatrix;
        int[Direction] lastCounter;
        DirectionState[Direction] directionState;
        mat4 _perspectiveMatrix;
    }

    void updateDimensions(int width, int height) {
        auto aspect = cast(float)width / height;
        auto fov_degrees = 60;
        writefln("fov_degrees: %s", fov_degrees);
        auto fov_radians = radians(fov_degrees);
        auto scale = 1f / tan(fov_radians / 2f);
        writefln("scale: %s", scale);
        _perspectiveMatrix = calculateFrustum(scale, aspect, 0.1f, 100f);
    }

    mat4 viewMatrix() {
        return _viewMatrix;
    }

    mat4 perspectiveMatrix() {
        return _perspectiveMatrix;
    }
    
    this() {
        
        reset();
    }
    
    void update() {
        foreach(Direction direction; EnumMembers!Direction) {
            float direction_offset = 0f;
            final switch (directionState[direction]) {
                case DirectionState.NONE:
                    break;
                case DirectionState.FIRST:
                    direction_offset = 0.05f;
                    directionState[direction] = DirectionState.REPEAT;
                    break;
                case DirectionState.REPEAT:
                    direction_offset = 0.1f;
                    break;
                case DirectionState.LAST:
                    direction_offset = lastFrameOffsets[lastCounter[direction]];
                    lastCounter[direction]--;
                    if (lastCounter[direction] == 2) {
                        directionState[direction] = DirectionState.NONE;
                    }
                    break;
            }

            direction_offset = direction_offset * (distance / 4);

            final switch (direction) {
                case Direction.UP:
                    target.x -= sin(plane_rotation.y) * direction_offset;
                    target.z += cos(plane_rotation.y) * direction_offset;
                    break;
                case Direction.DOWN:
                    target.x += sin(plane_rotation.y) * direction_offset;
                    target.z -= cos(plane_rotation.y) * direction_offset;
                    break;
                case Direction.LEFT:
                    target.x += sin(plane_rotation.y - (PI/2)) * direction_offset;
                    target.z -= cos(plane_rotation.y - (PI/2)) * direction_offset;
                    break;
                case Direction.RIGHT:
                    target.x -= sin(plane_rotation.y - (PI/2)) * direction_offset;
                    target.z += cos(plane_rotation.y - (PI/2)) * direction_offset;
                    break;
            }
        }

        vec3 rotation = vec3(plane_rotation, 0f);

        mat4 rotate = mat4.identity
            .rotatey(plane_rotation.y)
            ;

        mat4 x_axis_rotate = mat4.identity
            .rotatex(plane_rotation.x);

        mat4 target_translate = mat4.identity
            .translate(-target.x, -target.y, -target.z)
            ;

        mat4 camera_translate = mat4.identity
            .translate(0, 0, distance)
            ;

        _viewMatrix = camera_translate *
            x_axis_rotate *
            rotate *
            target_translate;
    }

    void reset() {
        target = defaultTarget;
        plane_rotation = defaultRotation;
        foreach(Direction direction; EnumMembers!Direction) {
            directionState[direction] = DirectionState.NONE;
        }
        foreach(Direction direction; EnumMembers!Direction) {
            lastCounter[direction] = 0;
        }
    }

    void keyPressed(Direction k) {
        directionState[k] = DirectionState.FIRST;
    }

    void keyUnpressed(Direction k) {
        if (directionState[k] != DirectionState.NONE) {
            directionState[k] = DirectionState.LAST;
        }
        lastCounter[k] = cast(int)lastFrameOffsets.length - 1;
    }

    void updateRotation(float x, float y) {
        plane_rotation.x += radians(x);
        plane_rotation.y += radians(y);
        plane_rotation.x = min(0, plane_rotation.x);
        plane_rotation.x = max(-PI/2, plane_rotation.x);
    }

    void updateDistance(float diff) {
        distance += diff;
        distance = min(50f, distance);
        distance = max(1f, distance);
    }
}
