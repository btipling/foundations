#extension GL_ARB_bindless_texture : require

layout(bindless_sampler) uniform sampler2D f_samp;
layout(bindless_sampler) uniform sampler2D f_samp_1;
layout(bindless_sampler) uniform sampler2D f_samp_2;
layout(bindless_sampler) uniform sampler2D f_samp_3;
layout(bindless_sampler) uniform samplerCube f_cubemap;
layout(bindless_sampler) uniform sampler3D f_3d_samp;
