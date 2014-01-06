#version 330 core
#
layout(std140) uniform Material {
    vec4 diffuse;
    vec4 ambient;
    vec4 specular;
    vec4 emissive;
    float shininess;
    int texCount;
} material;

uniform sampler2D tex;

out vec4 color;
in vec3 Tex_Coord;

void main()
{
    if (material.texCount == 0) {
        // Until we have lights, this will have to do.
        color = material.diffuse + material.ambient * 0.5;
    } else {
        color = texture(tex, vec2(Tex_Coord));
    }
}
