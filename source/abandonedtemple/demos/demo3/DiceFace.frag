#version 330 core
#
uniform sampler2D tex;

out vec4 color;
in vec3 Color;
in vec2 Tex_Coord;


void main()
{
    color = texture(tex, Tex_Coord);
    color = mix(vec4(Color, 1), color, color.a);
}
