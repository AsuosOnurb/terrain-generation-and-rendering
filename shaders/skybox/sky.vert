#version 440

uniform mat4 m_pvm;
uniform mat4 m_model;

uniform float sun_rho;
uniform float sun_theta;
uniform float sun_phi;

uniform vec4 camera_position;

in vec4 position;	// local space
in vec2 texCoord0;	// local space


// The data to be sent to the fragment shader
out Data {
	vec4 sunCenter; // In world space
	vec4 vertexPosition; // In world space
	vec2 texCoord;
} DataOut;


void main () {
	
	// Pass-through the texture coordinates
	DataOut.texCoord = texCoord0;

	/*
		We can do some math here.
		The skybox/dome sphere has a radius Rho.
		The sun has two spherical spatial coordinates: Theta and Phi uniforms.
		These values are manipulated from Nau's UI.
		
		Conveting those coords. to cartesian coords., we have:
		X = Rho * sin(Phi) * cos(Theta)
		Y = Rho * cos(Phi)
		Z = Rho * sin(Phi) * sin(Theta)

		The sun will be centered on those coordinates: C=(X, Y, Z);
	*/
	
	DataOut.sunCenter =  vec4 (
		sun_rho * sin(sun_phi) * cos(sun_theta),
		sun_rho * cos(sun_phi),
		sun_rho * sin(sun_phi) * sin(sun_theta),
		1
	);
	

	DataOut.vertexPosition = m_model * position;
    gl_Position = m_pvm * position ;
}