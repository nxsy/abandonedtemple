#version 330 core
layout(location = 0) in vec3 pos;
layout(location = 1) in vec3 tex_coord;

uniform mat4 u_transform;
uniform vec4 u_offset;
uniform mat4 u_frustum;

out vec3 Tex_Coord;

void main(){
    Tex_Coord = tex_coord;
    gl_Position = (vec4(pos,1) * u_transform + u_offset) * u_frustum;
}
