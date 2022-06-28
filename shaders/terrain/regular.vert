#version 440

uniform mat4 m_model;

uniform vec4 camera_position;



in vec4 position;	// local/model space

// "Grass/Green" texture
in vec2 texCoord0;  


void main () {

	

  	vec4 pos = position;
  	// pos += camera_position;

  	// Update vertex position relative to camera's position
  	pos.x += floor(camera_position.x);
  	pos.z += floor(camera_position.z);

  	pos.y = 0;
  	pos = m_model * pos ;

	gl_Position = pos;

}
