#version 440

uniform mat4 m_pvm;
uniform mat4 m_model;

in vec4 position;	// local/model space

// "Grass/Green" texture
in vec2 texCoord0;  


out Data {
    vec4 worldPosition;
    vec4 pvmPosition;

} DataOut;



void main () {

    DataOut.worldPosition = m_model * position;
    DataOut.pvmPosition = m_pvm * position;
	gl_Position = DataOut.pvmPosition;

}
