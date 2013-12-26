#version 330 core
layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 color;

uniform mat4 u_transform;
uniform int is_line;
uniform vec4 u_offset;
uniform mat4 u_frustum;

out vec3 Color;

void main(){
    if (is_line == 0) {
        Color = color;
    } else {
        Color = vec3(1, 1, 1);
    }
    gl_Position = (pos * u_transform + u_offset) * u_frustum;
}
