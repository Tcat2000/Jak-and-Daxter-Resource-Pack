#version 150

#moj_import <minecraft:projection.glsl>

in vec3 Position;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform float GameTime;

out vec4 texProj0;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position + vec3(0,sin(GameTime * 4000),0), 1.0);

    texProj0 = projection_from_position(gl_Position);
}
