#version 330 core
#
uniform sampler2D tex;

out vec4 color;
in vec3 Tex_Coord;

void main()
{
    color = texture(tex, vec2(Tex_Coord));
    color = mix(vec4(1,0,0,1), color, color.a);
}
