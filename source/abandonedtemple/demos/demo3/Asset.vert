#version 330 core
layout(location = 0) in vec3 a_pos;
layout(location = 1) in vec3 a_tex_coord;
layout(location = 2) in vec3 a_normal;
layout(location = 3) in vec3 a_tangent;
layout(location = 4) in vec3 a_bitangent;

layout(std140) uniform WVP {
    mat4 world;
    mat4 view;
    mat4 projection;
    mat4 wvp;
    mat4 wv;
} u_wvp;

out vec3 v_tex_coord;
out vec3 v_normal;
out vec3 v_tangent;
out vec3 v_bitangent;
out mat3 v_tbn_matrix;

void main(){
    v_tex_coord = a_tex_coord;
    v_normal = (u_wvp.world * vec4(a_normal, 0.0)).xyz;
    v_tangent = (u_wvp.world * vec4(a_tangent, 0.0)).xyz;
    v_bitangent = (u_wvp.world * vec4(a_bitangent, 0.0)).xyz;

    gl_Position = u_wvp.wvp * vec4(a_pos,1);

    v_tbn_matrix = transpose(mat3(v_tangent, v_bitangent, v_normal));
}
