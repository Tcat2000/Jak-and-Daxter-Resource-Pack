#version 150

#moj_import <minecraft:light.glsl>
#moj_import <minecraft:fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler2;
uniform sampler2D Sampler0;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec3 ModelOffset;
uniform int FogShape;
uniform float GameTime;
uniform vec3 ChunkOffset;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;

ivec2 getPos(vec3 pos) {
    return ivec2(ceil(pos.x / 0.003921568627451), ceil(pos.y / 0.003921568627451));
}

vec3 getPos2(vec3 pos) {
    return vec3(floor(mod(pos.x, 1) * 160) / 10, floor(mod(pos.y, 1) * 160) / 10, floor(mod(pos.z, 1) * 160) / 10);
}

/*void main() {
    vec3 pos = Position + ModelOffset;
    if(mod(Position.x, 1) < 0.006251 && mod(Position.x, 1) > 0.00625 || mod(Position.x, 1) < 0.99375 && mod(Position.x, 1) > 0.99374) {
        int x = int((floor(mod(Position.x, 1) + 0.5) * 2 - 1) + 0.5);
        int z = int((floor(mod(Position.z, 1) + 0.5) * 2 - 1) + 0.5);

        
        int X = int((floor(Position.x + 0.5)));
        int Y = int((floor(Position.y + 0.5)));
        int Z = int((floor(Position.z + 0.5)));

        pos = vec3(X, Y, Z) + ModelOffset + vec3(x * 4,0,z * 4);
    }
    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);

    vertexDistance = fog_distance(pos, FogShape);
    vertexColor = Color * minecraft_sample_lightmap(Sampler2, UV2);
    texCoord0 = UV0;
}*/

void main() {
    vec3 pos = getPos2(Position);
    vec3 realPos = Position + ModelOffset;
    //realPos = ModelOffset + Position * vec3(1,1,0.001);
    if((pos.x > 0.01 && pos.x < 0.2 || pos.x > 15.8 && pos.x > 15.99) && (pos.z > 0.01 && pos.z < 0.2 || pos.z > 15.80 && pos.z > 15.99)) {
        realPos = vec3(0);
        int x = 1;
        int z = 1;

        if(pos.x == 0.1) x = 0;
        if(pos.x == 15.9) x = 1;
        realPos += vec3(x * 4,0,z * 4);
    }
    gl_Position = ProjMat * ModelViewMat * vec4(realPos, 1.0);

    vertexDistance = fog_distance(pos, FogShape);
    vertexColor = Color * minecraft_sample_lightmap(Sampler2, UV2);
    texCoord0 = UV0;
}