#version 440


uniform sampler2D displacement_map;
uniform vec4 camera_position;

uniform float sun_rho;
uniform float sun_theta;
uniform float sun_phi; 

uniform float m_time;

in Data {
    vec4 worldPosition;
    vec4 pvmPosition;
} DataIn;


out vec4 colorOut;

vec4 getNoise(vec2 uv){
    vec2 uv0 = (uv/103.0)+vec2( m_time/17.0,  m_time/29.0);
    vec2 uv1 = uv/107.0-vec2( m_time/-19.0,  m_time/31.0);
    vec2 uv2 = uv/vec2(897.0, 983.0)+vec2( m_time/101.0,  m_time/97.0);
    vec2 uv3 = uv/vec2(991.0, 877.0)-vec2( m_time/109.0,  m_time/-113.0);
    vec4 noise = (texture2D(displacement_map, uv0)) +
                 (texture2D(displacement_map, uv1)) +
                 (texture2D(displacement_map, uv2)) +
                 (texture2D(displacement_map, uv3));
    return noise*0.5-1.0;
}

void sunLight(const vec3 surfaceNormal, const vec3 eyeDirection, float shiny, float spec, float diffuse,
              inout vec3 diffuseColor, inout vec3 specularColor){


    vec3 sunPosition = vec3 (
			sun_rho * sin(sun_phi) * cos(sun_theta),
			sun_rho * cos(sun_phi),
			sun_rho * sin(sun_phi) * sin(sun_theta)
		);

    vec3 sunColor = vec3(0.8, 0.8, 0.8);

    vec3 sunDirection = normalize(DataIn.worldPosition.xyz - sunPosition);

    vec3 reflection = normalize(reflect(-sunDirection, surfaceNormal));
    float direction = max(0.0, dot(eyeDirection, reflection));
    specularColor += pow(direction, shiny)*sunColor*spec;
    diffuseColor += max(dot(sunDirection, surfaceNormal),0.0)*sunColor*diffuse;
}

void main() {
		
        vec4 noise = getNoise(DataIn.worldPosition.xz);
        vec3 surfaceNormal = normalize(noise.xzy * vec3(2.0, 1.0, 2.0));



		vec3 diffuse = vec3(0.0);
        vec3 specular = vec3(0.0);

        vec3 worldToEye = DataIn.worldPosition.xyz - camera_position.xyz;
        vec3 eyeDirection = normalize(worldToEye);
        sunLight(surfaceNormal, eyeDirection, 100.0, 2.0, 0.5, diffuse, specular);



        float dist = length(worldToEye);

        vec2 screen = (DataIn.pvmPosition.xy/DataIn.pvmPosition.z + 1.0)*0.5;

        float distortionFactor = max(dist/100.0, 10.0);
        vec2 distortion = surfaceNormal.xz/distortionFactor;
        vec3 reflectionSample = vec3(texture2D(displacement_map, screen+distortion));


        vec3 color = vec3((diffuse+specular+vec3(0.1))*vec3(0.3, 0.5, 0.9));

        colorOut = vec4(color*(reflectionSample+vec3(0.1))*(diffuse+specular+0.3)*2.0, 1.0);
	


}

