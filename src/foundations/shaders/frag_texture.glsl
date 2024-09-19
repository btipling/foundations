
in vec2 f_tc;

layout (binding=0) uniform sampler2D f_samp;

void main()
{
   fo_frag_color = texture(f_samp, f_tc);
}
