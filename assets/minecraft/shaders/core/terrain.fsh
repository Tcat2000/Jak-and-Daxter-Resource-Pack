#version 150

#moj_import <minecraft:fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform vec3 ChunkOffset;
uniform float GameTime;

in vec3 Position;
in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

out vec4 fragColor;

float PI = 3.1415926535897932384626433832795;
int screenWidth = 64;

const mat2 myt = mat2(.12121212, .13131313, -.13131313, .12121212);
const vec2 mys = vec2(1e4, 1e6);

vec2 rhash(vec2 uv) {
  uv *= myt;
  uv *= mys;
  return fract(fract(uv / mys) * uv);
}

vec3 hash(vec3 p) {
    return fract(sin(vec3(dot(p, vec3(1.0, 57.0, 113.0)), dot(p, vec3(57.0, 113.0, 1.0)),dot(p, vec3(113.0, 1.0, 57.0)))) *43758.5453);
}

vec3 voronoi3d(const in vec3 x) {
  vec3 p = floor(x);
  vec3 f = fract(x);

  float id = 0.0;
  vec2 res = vec2(100.0);
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        vec3 b = vec3(float(i), float(j), float(k));
        vec3 r = vec3(b) - f + hash(p + b);
        float d = dot(r, r);

        float cond = max(sign(res.x - d), 0.0);
        float nCond = 1.0 - cond;

        float cond2 = nCond * max(sign(res.y - d), 0.0);
        float nCond2 = 1.0 - cond2;

        id = (dot(p + b, vec3(1.0, 57.0, 113.0)) * cond) + (id * nCond);
        res = vec2(d, res.x) * cond + res * nCond;

        res.y = cond2 * d + nCond2 * res.y;
      }
    }
  }

  return vec3(sqrt(res), abs(id));
}

float rand(vec2 c){
	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 p, float freq, float size){
	float unit = size/freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	//xy = 3.*xy*xy-2.*xy*xy*xy;
	xy = .5*(1.-cos(PI*xy));
	float a = rand((ij+vec2(0.,0.)));
	float b = rand((ij+vec2(1.,0.)));
	float c = rand((ij+vec2(0.,1.)));
	float d = rand((ij+vec2(1.,1.)));
	float x1 = mix(a, b, xy.x);
	float x2 = mix(c, d, xy.x);
	return mix(x1, x2, xy.y);
}

float pNoise(vec2 p, int res, float size, float f){
	float persistance = .5;
	float n = 0.;
	float normK = 0.;
	float amp = 1.;
	int iCount = 0;
	for (int i = 0; i<50; i++){
		n+=amp*noise(p, f, size);
		f*=2.;
		normK+=amp;
		amp*=persistance;
		if (iCount == res) break;
		iCount++;
	}
	float nf = n/normK;
	return nf*nf*nf*nf;
}

ivec4 getPos(vec4 color) {
    return ivec4(ceil(color.x / 0.003921568627451), ceil(color.y / 0.003921568627451), ceil(color.z / 0.003921568627451), ceil(color.w / 0.003921568627451));
}

const int dotCount = 50;
const int loopTime = 3;

float off(float x) {
    return sin(x / 1.) + sin(x / 2.) + sin(x / 3.) + sin(x / 4.) + sin(x / 5.) + sin(x / 6.) + sin(x / 7.) + sin(x / 8.) + sin(x / 9.) + sin(x / 10.);
}

float lerp(float a, float b, float c) {
    return (a * (1. - c)) + b * c;
}
vec4 addColors(vec4 color1, vec4 color2) {
    //Combined Color = (Alpha of Layer 1 * Color of Layer 1) + (Alpha of Layer 2 * Color of Layer 2) * (1 - Alpha of Layer 1)
    return vec4(lerp(color1.x, color2.x, color2.w), lerp(color1.y, color2.y, color2.w), lerp(color1.z, color2.z, color2.w), color2.w + color1.w * (1 - color2.w));
    //return vec4(color1.x * color1.w + color2.x * color2.w * (1 - color1.w), color1.y * color1.w + color2.y * color2.w * (1 - color1.w), color1.z * color1.w + color2.z * color2.w * (1 - color1.w), color1.w * color1.w + color2.w * color2.w * (1 - color1.w));
}

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    ivec4 pos = getPos(texture(Sampler0, texCoord0));
    if(pos.x < 16*5 && pos.y < 16*5 && pos.z == 0 && pos.w == 1) {
        float Time = mod(GameTime * 100, 1200);
        float staticOverlay = pNoise(pos.xy, 1, 300., 10.328) / 2.;
        float n1 = pNoise((pos.xy + vec2(sin(Time/10) * 1000,cos(Time/10) * 1000)) * 3, 1, 500., 10.600);
        float n2 = pNoise((pos.xy + vec2(sin(Time/10+1) * 1000,cos(Time/10+1) * 1000)) * 3, 2, 500., 10.328) / 2.;
        float c = n1 + n2;
        vec3 dColor = vec3(c,c,c);
        
        float blue = 0.;
        if(Time < 700.) blue = 0.;
        if(Time > 700. && Time < 800.) blue = (Time - 700.) / 100.;
        if(Time > 800. && Time < 1100.) blue = 1.;
        if(Time > 1100. && Time < 1200.) blue = 0. - (Time - 1100.) / 100.;
        blue = 0;
        
        vec3 blueColor = vec3(0.216,0.216,0.540);
        dColor = vec3(0.050, 0.050, 0.086);
        if(c > 0.297) dColor = vec3(0.588, 0.184, 0.890) * vec3(1.-blue) + blueColor * vec3(0. + blue);
        if(c > 0.158 && c < 0.225) dColor = vec3(0.301,0.196,0.313) * vec3(1.-blue) +blueColor * vec3(0. + blue);
        if(c > 0.140 && c < 0.150) dColor = vec3(0.301,0.196,0.313) * vec3(1.-blue) + blueColor * vec3(0. + blue);
        if(c > 0.125 && c < 0.136) dColor = vec3(0.301,0.196,0.313) * vec3(1.-blue) + blueColor * vec3(0. + blue);
        if(c > 0. && c < 0.0005) dColor = vec3(0.501,0.062,0.886) * vec3(1.-blue) + blueColor * vec3(0. + blue);
        if(c > 0.01 && c < 0.02) dColor = vec3(0.016,0.023,0.130) * vec3(1.-blue) + blueColor * vec3(0. + blue);

        
        color = vec4(dColor, 1);
    }
    if(pos.x < 16*5 && pos.y < 16*5 && pos.z == 1 && pos.w == 1) {
        float time = mod(GameTime * 400, float(loopTime));
        vec4 col = vec4(0.352,0.372,1.000, 0.423);
        vec2 res = vec2(16*5, 16*5);
        ivec2 dots[dotCount];
        //ivec2 dot = ivec2(float(sin(v)) * u_resolution.x / 2. * (1. - (time / 10.)), float(cos(v)) * u_resolution.x / 2. * (1. - (time / 10.))) + ivec2(u_resolution.x / 2., u_resolution.y / 2.);
        
        for(int i = 0; i < dotCount; i++) {
            float offsetTime = mod(time + off(float(i)), float(loopTime));
            float startOffset = off(float(i * 5)) / 10. * 6.2831853;
            float t = offsetTime / (float(loopTime) * 1.5);
            //float v = (2. * t * t - 2. * t * t * t) * float(loopTime) * (float(loopTime) * 1.5) * 10;
            float v = (t * 0.75 * ((t / loopTime) / 2 + 0.5)) * float(loopTime) * (float(loopTime) * 1.5) * 10;
            dots[i] = ivec2(float(sin(v + startOffset)) * res.x / 2. * (1. - (offsetTime / float(loopTime))), float(cos(v + startOffset)) * res.x / 2. * (1. - (offsetTime / float(loopTime)))) + ivec2(res.x / 2., res.y / 2.);
        }
        
        for(int i = 0; i < dotCount; i++) {
            float dist = sqrt(pow(pos.x - dots[i].x, 2) + pow(pos.y - dots[i].y, 2));
            float alpha = 1;
            vec2 rel = dots[i] - pos.xy;
            if(dist < 5) {
                alpha = 1 / (dist / 5);
                col = addColors(col, vec4(0.4 + off(i) / 20, 0.45, 1.0, 0.75));
                //col = col * vec3(1 - alpha,1 - alpha,1 - alpha) + vec3(0.5333 + (off(rel.x + 3 * (i+1)) + 5) / 50, 0.8902 + (off(rel.x + 3 * (i+1)) + 5) / 50, 0.9294) * vec3(alpha, alpha, alpha);
                //if(dist == 0) col = vec3(0.6863, 0.9059, 1.0);
            };
            float a = abs(pos.x - float(dots[i].x)) + abs(pos.y - float(dots[i].y));
        }
        color = col;
    }
    
    #ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
    #endif
    
    fragColor = color * vertexColor * ColorModulator;
}