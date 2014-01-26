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

uniform sampler2D tex;

out vec4 f_color;
in vec3 v_tex_coord;
in vec3 v_normal;

void main()
{
    vec4 ambient_color = u_global_lighting.color * u_global_lighting.ambient;

    float diffuse_factor = dot(normalize(v_normal), -u_global_lighting.direction.xyz);

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
}
