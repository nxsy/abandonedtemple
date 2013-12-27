#version 330 core
layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 color;
layout(location = 2) in vec2 tex_coord;

uniform mat4 u_transform;
uniform int is_line;
uniform vec4 u_offset;
uniform mat4 u_frustum;

out vec3 Color;
out vec2 Tex_Coord;

void main(){
    if (is_line == 0) {
        Color = color;
    } else {
        Color = color + vec3(0.1, 0.1, 0.1);
    }
    Tex_Coord = tex_coord;
    gl_Position = (pos * u_transform + u_offset) * u_frustum;
}
