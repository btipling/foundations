pub const c = @cImport({
    @cInclude("stb_perlin.h");
    @cDefine("STB_PERLIN_IMPLEMENTATION", {});
});
