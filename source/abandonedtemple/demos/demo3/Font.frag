#version 330 core
#
uniform sampler2D tex;

out vec4 color;
in vec2 Tex_Coord;

void main()
{
    vec4 tex_color = texture(tex, Tex_Coord);
    color.rgba = tex_color.rrrr;
}
