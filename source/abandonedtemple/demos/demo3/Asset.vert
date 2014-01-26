#version 330 core
layout(location = 0) in vec3 a_pos;
layout(location = 1) in vec3 a_tex_coord;
layout(location = 2) in vec3 a_normal;

layout(std140) uniform WVP {
    mat4 world;
    mat4 view;
    mat4 projection;
    mat4 wvp;
} u_wvp;

out vec3 v_tex_coord;
out vec3 v_normal;

void main(){
    v_tex_coord = a_tex_coord;
    v_normal = (u_wvp.world * vec4(a_normal, 0.0)).xyz;
    gl_Position = u_wvp.wvp * vec4(a_pos,1);
}
