#version 330 core
layout(location = 0) in vec3 pos;
layout(location = 1) in vec2 tex_coord;

out vec2 Tex_Coord;

void main() {
    Tex_Coord = tex_coord;
    gl_Position = vec4(pos, 1);
}
