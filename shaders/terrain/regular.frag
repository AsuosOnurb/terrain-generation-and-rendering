#version 440


// A "green/grass" texture
uniform sampler2D texture_grass_albedo;
uniform sampler2D texture_sand_albedo;
uniform sampler2D texture_rock_albedo;
uniform sampler2D texture_snow_albedo;

// uniform float dirt_start;
uniform float grass_start;
uniform float rock_start;
uniform float snow_start;

/*
uniform float grass_end;
uniform float dirt_end;
uniform float rock_start;
uniform float rock_end;
uniform float snow_start;
uniform float snow_end;

uniform float smoothstep_value;
*/

uniform float texture_tiling;

uniform mat4 m_view;
uniform mat3 m_normal;

uniform float sun_rho;
uniform float sun_theta;
uniform float sun_phi;

uniform vec4 camera_position;

uniform	vec4 specular;
uniform	float shininess;

uniform float noise_height;


uniform float m_time;

// Light Direction
// uniform vec4 l_dir;

// What kind of shading should we use? Heatmap? Realistic?
uniform int color_coding;


in Data {
	vec4 position;
	vec4 lightDirection;
	vec3 normal;
} DataIn;


out vec4 colorOut;



/* ========================= Voronoi Noise  ============================== */
		 		
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




/* ========================= Untiling Textures ============================== */
vec4 hash4( vec2 p ) { return fract(sin(vec4( 1.0+dot(p,vec2(37.0,17.0)), 
                                              2.0+dot(p,vec2(11.0,47.0)),
                                              3.0+dot(p,vec2(41.0,29.0)),
                                              4.0+dot(p,vec2(23.0,31.0))))*103.0); }



vec4 textureNoTile( sampler2D samp, in vec2 uv )
{
	// Taken from https://iquilezles.org/articles/texturerepetition/
	
    vec2 p = floor( uv );
    vec2 f = fract( uv );
	
    // derivatives (for correct mipmapping)
    vec2 ddx = dFdx( uv );
    vec2 ddy = dFdy( uv );
    
    // voronoi contribution
    vec4 va = vec4( 0.0 );
    float wt = 0.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = vec2( float(i), float(j) );
        vec4 o = hash4( p + g );
        vec2 r = g - f + o.xy;
        float d = dot(r,r);
        float w = exp(-5.0*d );
        vec4 c = textureGrad( samp, uv + o.zw, ddx, ddy );
        va += w*c;
        wt += w;
    }
	
    // normalization
    return va/wt;

}



/* ========================= Height based texture blending ============================== */

vec3 blend(vec3 tex1, float t1, vec3 tex2, float t2) 
{
	return tex1.rgb * t1 + tex2.rgb * t2;
}


vec3 blend1(vec3 tex1, float t1, vec3 tex2, float t2) 
{
	return tex1.rgb * t1 + tex2.rgb * t2;
}


/* ============================================================================================ */
void main() {
		
	vec3 normal = normalize(DataIn.normal);

	if (color_coding == 0) {
		// Realistic shading
	
	
		vec3 n = normalize(DataIn.normal);
		vec3 e = normalize(vec3(camera_position.xyz));
		vec3 l = normalize(vec3(m_view * normalize(DataIn.lightDirection)));


		vec2 textureCoords = vec2(DataIn.position.x, DataIn.position.z) / texture_tiling;

		vec3 tex1, tex2;
		vec4 baseColor;


		float vertexHeight = DataIn.position.y / noise_height;

		
		vec4 dirtColor = textureNoTile(texture_sand_albedo, textureCoords);
		vec4 rockColor = textureNoTile(texture_rock_albedo, textureCoords);
		vec4 snowColor = textureNoTile(texture_snow_albedo, textureCoords);
		vec4 grassColor = textureNoTile(texture_grass_albedo, textureCoords);

		if (vertexHeight < grass_start){
			float f = smoothstep(0,grass_start, vertexHeight);
			baseColor = mix(dirtColor, grassColor , f);
		}
		else if(grass_start <= vertexHeight && vertexHeight < rock_start){
			float f = smoothstep(grass_start,rock_start, vertexHeight);
			baseColor = mix(grassColor, rockColor , f);
		}
		else{
			float f = smoothstep(rock_start, snow_start, vertexHeight);
			baseColor = mix(rockColor, snowColor , f);
		}

		vec4 spec = vec4(0.0);
		float intensity = max(dot(n, l), 0.0);

		if (intensity > 0.0) 
		{
			// compute the half vector
			vec3 h = normalize(l + e);	
			// compute the specular intensity
			float intSpec = max(dot(h,n), 0.0);
			// compute the specular term into spec
			spec = specular * pow(intSpec, 0.02);
		}

		colorOut = max(intensity * baseColor + spec, 0.15 * baseColor);

		
	}
	else if (color_coding == 1)
	{
		// Heat-map color shading
		colorOut = vec4(0.5, 0.1, 0.6, 1.0);
		colorOut.r += DataIn.position.y / noise_height;
	}
	else if (color_coding == 2) 
	{
		// Shading with Voronoi noise 
		vec2 u_resolution = vec2(5,5) * texture_tiling;
		vec2 st = vec2(DataIn.position.x, DataIn.position.z)/u_resolution.xy;
		st.x *= u_resolution.x/u_resolution.y;
		vec3 color = vec3(0.0);

		// Scale
		st *= 3.;
		vec3 c = voronoiNoise(st);

		// isolines
		color = c.x*(0.5 + 0.5*sin(64.0*c.x))*vec3(1.0);
		// borders
		color = mix( vec3(1.0), color, smoothstep( 0.01, 0.02, c.x ) );
		// feature points
		float dd = length( c.yz );
		color += vec3(1.)*(1.0-smoothstep( 0.0, 0.04, dd));

		colorOut = vec4(color,1.0);
	}
	else if (color_coding == 3) 
	{
		// Debug normals with color coding
		colorOut = vec4(normal, 1.0);
	}
	


}

