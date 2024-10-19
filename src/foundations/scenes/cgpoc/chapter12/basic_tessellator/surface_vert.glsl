#version 460

//#include "src/foundations/shaders/vertex_outs.glsl"

void main(void) { 
    const vec4 vertices[] = 
    vec4[](vec4(-1.0,  0.5, -1.0, 1.0), vec4(-0.5, 0.5, -1.0, 1.0),
           vec4( 0.5,  0.5, -1.0, 1.0), vec4( 1.0, 0.5, -1.0, 1.0),

           vec4(-1.0,  0.0, -0.5, 1.0), vec4(-0.5, 0.0, -0.5, 1.0),
           vec4( 0.5,  0.0, -0.5, 1.0), vec4( 1.0, 0.0, -0.5, 1.0),
        
           vec4(-1.0,  0.0,  0.5, 1.0), vec4(-0.5, 0.0,  0.5, 1.0),
           vec4( 0.5,  0.0,  0.5, 1.0), vec4( 1.0, 0.0,  0.5, 1.0),
        
           vec4(-1.0, -0.5,  1.0, 1.0), vec4(-0.5, 0.3,  1.0, 1.0),
           vec4( 0.5,  0.3,  1.0, 1.0), vec4( 1.0, 0.3,  1.0, 1.0));
    gl_Position = vertices[gl_VertexID];
}