pub fn init() *c.ecs_world_t {
    return c.ecs_init() orelse @panic("flecs_err");
}

pub fn deinit(world: *c.ecs_world_t) void {
    _ = c.ecs_fini(world);
}

const c = @import("../c.zig").c;
