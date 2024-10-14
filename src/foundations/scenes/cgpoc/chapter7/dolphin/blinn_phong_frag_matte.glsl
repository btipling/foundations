
in vec4 fo_shadow_coord;

float f_lookup(float f_ox, float f_oy)
{
    float f_t = textureProj(
        f_shadow_texture0,
        fo_shadow_coord + vec4(
            f_ox * 0.0001 * fo_shadow_coord.w,
            f_oy * 0.0001 * fo_shadow_coord.w,
            0,
            0.0
        ));
    return f_t;
}

void main()
{
    Light f_light = f_lights[0];
    vec4 f_texture_color = texture(f_samp_1, f_tc);

    vec3 f_N = normalize(fo_normal);
    
    vec3 f_L = normalize(f_light.direction.xyz);

    float cosTheta = dot(f_L, f_N);

    float f_shadow_factor = 0.0;
    float swidth = 2.5;
    vec2 f_offset = mod(floor(gl_FragCoord.xy), 2.0) * swidth;
    f_shadow_factor += f_lookup(-1.5 * swidth + f_offset.x, 1.5 * swidth - f_offset.y);
    f_shadow_factor += f_lookup(-1.5 * swidth + f_offset.x, -0.5 * swidth - f_offset.y);
    f_shadow_factor += f_lookup(0.5 * swidth + f_offset.x, 1.5 * swidth - f_offset.y);
    f_shadow_factor += f_lookup(0.5 * swidth + f_offset.x, -0.5 * swidth - f_offset.y);
    f_shadow_factor = f_shadow_factor/4.0;

    vec3 f_ambient = (f_global_ambient + f_light.ambient).xyz;
    vec3 f_diffuse = f_light.diffuse.xyz * max(cosTheta, 0.0);

    if (fo_normal[0] < 0.01 && fo_normal[1] > 0.99) {
        f_shadow_factor = 1.0;
    }

    fo_frag_color = f_texture_color * vec4((f_ambient.xyz + f_shadow_factor * (f_diffuse.xyz)), 1.0);
}