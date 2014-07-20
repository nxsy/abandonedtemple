#version 330 core
#
layout(std140) uniform Material {
    vec4 diffuse;
    vec4 ambient;
    vec4 specular;
    vec4 emissive;
    float shininess;
    int texCount;
} u_material;

layout(std140) uniform GlobalLighting {
    vec4 color;
    vec4 direction;
    float diffuse;
    float ambient;
} u_global_lighting;

layout(std140) uniform WVP {
    mat4 world;
    mat4 view;
    mat4 projection;
    mat4 wvp;
    mat4 wv;
} u_wvp;

uniform sampler2D tex;
uniform sampler2D bumpTex;

uniform int normal_mapping;
uniform int show_diffuse_factor;
uniform int show_bump_map;
uniform int show_bump_map_raw;

in vec3 v_tex_coord;
in vec3 v_normal;
in vec3 v_tangent;
in vec3 v_bitangent;
in mat3 v_tbn_matrix;

out vec4 f_color;

void main()
{
    vec3 bump_normal_raw;
    vec3 bump_normal;
    vec4 ambient_color = u_global_lighting.color * u_global_lighting.ambient;

    vec3 normal = normalize(v_normal);

    vec3 light_direction = -u_global_lighting.direction.xyz;

    if (normal_mapping > 0) {
        if (u_material.texCount > 1) {
            bump_normal_raw = texture(bumpTex, v_tex_coord.xy).xyz;
            bump_normal = 2.0 * bump_normal_raw - vec3(1.0, 1.0, 1.0);
            if (normal_mapping > 1) {
                normal = v_tbn_matrix * bump_normal;
                normal = normalize(normal);
            } else {
                vec3 tangent = normalize(v_tangent);
                tangent = normalize(tangent - dot(tangent, normal) * normal);
                vec3 bitangent = cross(tangent, normal);
                mat3 tbn_matrix = mat3(tangent, bitangent, normal);
                normal = tbn_matrix * bump_normal;
                normal = normalize(normal);
            }
        }
    }

    float diffuse_factor = clamp(dot(normal, light_direction), 0, 1);

    vec4 diffuse_color;
    if (diffuse_factor > 0) {
        diffuse_color = u_global_lighting.color * u_global_lighting.diffuse * diffuse_factor;
    } else {
        diffuse_color = vec4(0,0,0,0);
    }

    if (u_material.texCount == 0) {
        // Until we have lights, this will have to do.
        f_color = u_material.diffuse + u_material.ambient * 0.2;
    } else {
        f_color = texture(tex, v_tex_coord.xy) * (diffuse_color + ambient_color);
    }

    // Debug modes
    if (show_diffuse_factor > 0) {
        f_color = vec4(diffuse_factor, diffuse_factor, diffuse_factor, 1);
    }
    if (show_bump_map > 0) {
        f_color = vec4(bump_normal, 1);
    }
    if (show_bump_map_raw > 0) {
        f_color = vec4(bump_normal_raw, 1);
    }
}
