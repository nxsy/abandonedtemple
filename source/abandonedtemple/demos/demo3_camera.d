module abandonedtemple.demos.demo3_camera;

import std.stdio : writefln;
import gl3n.linalg;

struct Camera {
    vec3 offset = vec3(0f);
    vec3 rotation = vec3(0f);
    mat4 viewMatrix;

    void update() {
        writefln("rotation x: %f, y: %f, z: %f", rotation.x, rotation.y, rotation.z);
        writefln("offset x: %f, y: %f, z: %f", offset.x, offset.y, offset.z);
        viewMatrix = mat4.identity
            .translate(offset.x, offset.y, offset.z)
            .rotatex(rotation.x)
            .rotatey(rotation.y)
            .rotatez(rotation.z)
            ;
    }
}