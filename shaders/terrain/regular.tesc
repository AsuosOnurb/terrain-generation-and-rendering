#version 440


layout(vertices = 4) out;

// Tesselation levels are no longer controlled via UI.
// Tess. Levels are now calculacted based on distance to camera.
// uniform float olevel = 4.0, ilevel= 4.0;
uniform vec4 camera_position;
uniform int max_outter_tesselation;
uniform int max_inner_tesselation;
uniform float tesselation_dist_thresh;
uniform int easing_function;
uniform int apply_dynamic_lod; // Should variable LOD be used?


out vec4 posTC[];




float easeOutCirc(float x) {
	return sqrt(1 - pow(x - 1, 2));
}

float easeOutExpo(float x) 
{
	return x == 1 ? 1 : 1 - pow(2, -10 * x);
}

float easeOutQuart(float x) 
{
	return 1 - pow(1 - x, 4);
}

float easeOutQuint(float x) 
{
	return 1 - pow(1 - x, 5);
}

float applyEasing(float x) 
{
	if (easing_function == 0)
		// EaseInCirc
		return easeOutCirc(x);

	else if (easing_function == 1) 
		// EaseOutCirc
		return easeOutExpo(x);

	else if (easing_function == 2) 
		// EaseInExpo
		return easeOutQuart(x);
	else if (easing_function == 3)
		// EaaseInQuart
		return easeOutQuint(x);
}

void main () {

	posTC[gl_InvocationID] = gl_in[gl_InvocationID].gl_Position;


	/*
	if (gl_InvocationID == 0) {
		gl_TessLevelOuter[0] = olevel;
		gl_TessLevelOuter[1] = olevel;
		gl_TessLevelOuter[2] = olevel;
		gl_TessLevelOuter[3] = olevel;
		gl_TessLevelInner[0] = ilevel;
		gl_TessLevelInner[1] = ilevel;
	}
	*/

	
	float outterTess;
	float innerTess;

	if (apply_dynamic_lod == 0)
	{
		// Manipulate LOD based on distance
		int vertA = 0, vertB = 0;
		if (gl_InvocationID == 0) 
		{
			vertA = 0;
			vertB = 1;
		} 
		else if (gl_InvocationID == 1)
		{
			vertA = 0;
			vertB = 3;
		} 
		else if (gl_InvocationID == 2) 
		{
			vertA = 2;
			vertB = 3;
		}
		else if (gl_InvocationID == 3)
		{
			vertA = 1;
			vertB = 2;
		}

		precise vec4 midPoint = 0.5 * (gl_in[vertA].gl_Position + gl_in[vertB].gl_Position);
		float camDist = clamp( 
								length(midPoint - camera_position) / tesselation_dist_thresh, 
								0, 
								1
						);

		camDist = applyEasing(camDist);

		outterTess = mix(max_outter_tesselation, 0, camDist);
		innerTess = mix(max_inner_tesselation, 0, camDist);
	}
	else 
	{
		// No Dynamic LOD. Static tesselation levels instead.
		outterTess = max_outter_tesselation;
		innerTess = max_inner_tesselation;
	}

	


	gl_TessLevelOuter[0] = outterTess;
	gl_TessLevelOuter[1] = outterTess;
	gl_TessLevelOuter[2] = outterTess;
	gl_TessLevelOuter[3] = outterTess;
	gl_TessLevelInner[0] = innerTess;
	gl_TessLevelInner[1] = innerTess;
	
}
