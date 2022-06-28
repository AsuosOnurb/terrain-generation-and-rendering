#version 440

layout(quads, equal_spacing, ccw) in;

in vec4 posTC[];


out Data {
	vec4 position;
	vec4 lightDirection;
	vec3 normal;
} DataOut;


uniform	mat4 m_pv;
uniform mat4 m_model;
uniform	mat3 m_normal;


uniform float m_time;

uniform int noise_function; 	// The noise function used for height computation
uniform float noise_scale; 		// Scales the noise function's output
uniform int noise_octaves; 		// How many octaves are applied
uniform float noise_gain;
uniform float noise_shift;
uniform float noise_lacunarity;
uniform float noise_exponentiation;
uniform float noise_height;


uniform float sun_rho;
uniform float sun_theta;
uniform float sun_phi;







/* ================================================================ */
#define M_PI 3.14159265358979323846

float rand(vec2 co){return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);}
float rand (vec2 co, float l) {return rand(vec2(rand(co), l));}
float rand (vec2 co, float l, float t) {return rand(vec2(rand(co, l), t));}

float perlin(vec2 p, float dim, float time) {
	vec2 pos = floor(p * dim);
	vec2 posx = pos + vec2(1.0, 0.0);
	vec2 posy = pos + vec2(0.0, 1.0);
	vec2 posxy = pos + vec2(1.0);
	
	float c = rand(pos, dim, time);
	float cx = rand(posx, dim, time);
	float cy = rand(posy, dim, time);
	float cxy = rand(posxy, dim, time);
	
	vec2 d = fract(p * dim);
	d = -0.5 * cos(d * M_PI) + 0.5;
	
	float ccx = mix(c, cx, d.x);
	float cycxy = mix(cy, cxy, d.x);
	float center = mix(ccx, cycxy, d.y);
	
	return center * 2.0 - 1.0;
}

/* ==================================================================
		 		Simplex Noise
==================================================================== */
vec3 simplexPermute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float simplexNoise(float xx, float yy) 
{
	vec2 v = vec2(xx, yy);
	const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
	vec2 i  = floor(v + dot(v, C.yy) );
	vec2 x0 = v -   i + dot(i, C.xx);
	vec2 i1;
	i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec4 x12 = x0.xyxy + C.xxzz;
	x12.xy -= i1;
	i = mod(i, 289.0);
	vec3 p = simplexPermute( simplexPermute( i.y + vec3(0.0, i1.y, 1.0 ))
	+ i.x + vec3(0.0, i1.x, 1.0 ));
	vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
		dot(x12.zw,x12.zw)), 0.0);
	m = m*m ;
	m = m*m ;
	vec3 x = 2.0 * fract(p * C.www) - 1.0;
	vec3 h = abs(x) - 0.5;
	vec3 ox = floor(x + 0.5);
	vec3 a0 = x - ox;
	m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
	vec3 g;
	g.x  = a0.x  * x0.x  + h.x  * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return 130.0 * dot(m, g);
}



/* ==================================================================
		 		Voronoi Noise
==================================================================== */
vec2 voronoiRandom( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

vec3 voronoiNoise(vec2 x ) {
    vec2 n = floor(x);
    vec2 f = fract(x);

	float time = m_time / 1000;

    // first pass: regular voronoi
    vec2 mg, mr;
    float md = 8.0;
    for (int j= -1; j <= 1; j++) {
        for (int i= -1; i <= 1; i++) {
            vec2 g = vec2(float(i),float(j));
            vec2 o = voronoiRandom( n + g );
            o = 0.5 + 0.5*sin( time + 6.2831*o );

            vec2 r = g + o - f;
            float d = dot(r,r);

            if( d<md ) {
                md = d;
                mr = r;
                mg = g;
            }
        }
    }

    // second pass: distance to borders
    md = 8.0;
    for (int j= -2; j <= 2; j++) {
        for (int i= -2; i <= 2; i++) {
            vec2 g = mg + vec2(float(i),float(j));
            vec2 o = voronoiRandom( n + g );
            o = 0.5 + 0.5*sin( time + 6.2831*o );

            vec2 r = g + o - f;

            if ( dot(mr-r,mr-r)>0.00001 ) {
                md = min(md, dot( 0.5*(mr+r), normalize(r-mr) ));
            }
        }
    }
    return vec3(md, mr);
}

/* ====================================================================== */
float noiseFunction	(float x, float y, int octave) 
{
	const vec2 point = vec2(x, y);
	if (noise_function == 0)
		// Perlin Noise
	{	const int seed = 100;
		return perlin(point, pow(2,octave), seed + octave * 100);
	}
	else if (noise_function == 1) 
	{
		// Simplex Noise
		return simplexNoise(x, y);
	}
	else if (noise_function == 2) 
	{
		// Voronoi noise
		const vec3 v = voronoiNoise(vec2(x, y));
		return v.r;
	}
}

/**
	Computes noise based on FBM (Fractional Brownian Motion) 

*/
float applyNoise(float x, float y) 
{
	const float scaledX = x / noise_scale;
	const float scaledY = y / noise_scale;
	
	const float G = noise_gain;

	float amp = 1.0;
	float freq = 1.0;
	float normalization = 0.0;
	float total = 0.0;
	for (int o = 0; o < noise_octaves; o++) 
	{
		const float noiseValue = noiseFunction(scaledX * freq, scaledY * freq, o) + noise_shift;

		total += noiseValue * amp;
		normalization += amp;
		amp *= G;
		freq *= noise_lacunarity;
	}

	total /= normalization;

	return pow(total, noise_exponentiation) * noise_height;
}

void main() {
	float u = gl_TessCoord.x;
	float v = gl_TessCoord.y;
	
	vec4 a1 = mix(posTC[0],posTC[1],u);
	vec4 a2 = mix(posTC[3],posTC[2],u);

	vec4 position =  mix(a1, a2, v);

	position.y += applyNoise(position.x, position.z);

	float OFFSET = 0.01;

	vec3 p4 = vec3 (
		0 + OFFSET,
		applyNoise(position.x + OFFSET, position.z),
		0
	);
  	
  	vec3 p2 = vec3 (
  		0,
  		applyNoise(position.x,position.z + OFFSET),
  		0 + OFFSET
  	);
	
	vec3 p3 = vec3 (
		0-OFFSET,
		applyNoise(position.x - OFFSET, position.z),
		0
	);

  	vec3 p1 = vec3 (
  		0, 
  		applyNoise(position.x, position.z - OFFSET),
  		0 - OFFSET
  	);

  	vec3 v1 = p2 - p1;
  	vec3 v2 = p4 - p3;



  	DataOut.normal = normalize(m_normal * cross(v1, v2));
	DataOut.position = position;



	vec4 sunPosition = vec4 (
			sun_rho * sin(sun_phi) * cos(sun_theta),
			sun_rho * cos(sun_phi),
			sun_rho * sin(sun_phi) * sin(sun_theta),
			1
	);
	DataOut.lightDirection = sunPosition - DataOut.position;



	gl_Position = m_pv * position;

	
}

