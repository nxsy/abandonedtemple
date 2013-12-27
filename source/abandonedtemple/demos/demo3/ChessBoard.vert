#version 330 core
layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 color;

uniform mat4 u_transform;
uniform vec4 u_offset;
uniform mat4 u_frustum;
uniform int width;

out vec3 Color;

void main(){
    float x;
    x = floor(gl_InstanceID / width);
    float y = mod(gl_InstanceID, width);
    if (mod(gl_InstanceID + x, 2) > 0.1) {
        Color = vec3(0.9, 0.9, 0.9);
    } else {
        Color = vec3(0.7, 0.7, 0.7);
    }
    vec4 offset = u_offset + vec4(y * 0.8, 0, -x * 0.8, 0);
    gl_Position = (pos * u_transform + offset) * u_frustum;
}
