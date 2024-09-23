allocator: std.mem.Allocator,
sun: object.object = .{ .norender = .{} },
sun_uniform: rhi.Uniform = .empty,
earth: object.object = .{ .norender = .{} },
earth_uniform: rhi.Uniform = .empty,
moon: object.object = .{ .norender = .{} },
shuttle: object.object = .{ .norender = .{} },
moon_uniform: rhi.Uniform = .empty,
view_camera: *physics.camera.Camera(*SimpleSolarSystem, physics.Integrator(physics.SmoothDeceleration)),
stack: [10]math.matrix = undefined,
current_stack_index: u8 = 0,
materials: rhi.Buffer,
lights: rhi.Buffer,
bg: object.object = .{ .norender = .{} },
sun_texture: ?rhi.Texture = null,
earth_texture: ?rhi.Texture = null,
moon_texture: ?rhi.Texture = null,
shuttle_texture: ?rhi.Texture = null,
shuttle_uniform: rhi.Uniform = .empty,
ctx: scenes.SceneContext,
initialized: bool = false,

const SimpleSolarSystem = @This();

const num_cubes = 1;

const vertex_shader: []const u8 = @embedFile("blinn_phong_vert.glsl");
const texture_frag_shader: []const u8 = @embedFile("texture_frag.glsl");
const frag_texture_shader: []const u8 = @embedFile("blinn_phong_texture_frag.glsl");
const vertex_static_shader: []const u8 = @embedFile("../../../../shaders/i_obj_static_vert.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Simple Solar System",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *SimpleSolarSystem {
    const ss = allocator.create(SimpleSolarSystem) catch @panic("OOM");
    errdefer allocator.destroy(ss);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*SimpleSolarSystem, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        ss,
        integrator,
        .{ 3, -15, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    const mats = [_]lighting.Material{
        .{
            .ambient = [4]f32{ 0.2, 0.2, 0.2, 0.0 },
            .diffuse = [4]f32{ 0.8, 0.8, 0.8, 0.0 },
            .specular = [4]f32{ 0.5, 0.5, 0.5, 0.0 },
            .shininess = 32.0,
        },
    };

    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd);
    errdefer mats_buf.deinit();

    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.01, 0.01, 0.01, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = [4]f32{ 0.75, -0.5, -0.5, 0.0 },
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .direction,
        },
    };
    const ld: rhi.Buffer.buffer_data = .{ .lights = lights[0..] };
    var lights_buf = rhi.Buffer.init(ld);
    errdefer lights_buf.deinit();

    ss.* = .{
        .allocator = allocator,
        .view_camera = cam,
        .materials = mats_buf,
        .lights = lights_buf,
        .ctx = ctx,
    };
    ss.stack[0] = math.matrix.identity();
    ss.renderBG();
    ss.renderSun();
    ss.renderEarth();
    ss.renderMoon();
    ss.renderShuttle();
    ss.initialized = true;
    return ss;
}

pub fn deinit(self: *SimpleSolarSystem, allocator: std.mem.Allocator) void {
    if (self.sun_texture) |st| {
        st.deinit();
    }
    if (self.earth_texture) |et| {
        et.deinit();
    }
    if (self.moon_texture) |mt| {
        mt.deinit();
    }
    if (self.shuttle_texture) |st| {
        st.deinit();
    }
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    self.materials.deinit();
    self.materials = undefined;
    self.lights.deinit();
    self.lights = undefined;
    allocator.destroy(self);
}

fn pushStack(self: *SimpleSolarSystem, m: math.matrix) void {
    const next_stack_index = self.current_stack_index + 1;
    self.stack[next_stack_index] = math.matrix.transformMatrix(self.stack[self.current_stack_index], m);
    self.current_stack_index = next_stack_index;
}

fn popStack(self: *SimpleSolarSystem) void {
    self.current_stack_index -= 1;
}

fn resetStack(self: *SimpleSolarSystem) void {
    self.current_stack_index = 0;
}

pub fn draw(self: *SimpleSolarSystem, dt: f64) void {
    // sun
    // sun position already at 0
    // sun rotation
    self.pushStack(math.matrix.rotationX(@floatCast(dt)));
    self.sun_uniform.setUniformMatrix(self.stack[self.current_stack_index]);
    self.popStack(); // remove sun rotation
    // earth
    self.pushStack(math.matrix.translate(
        0,
        @sin(@as(f32, @floatCast(dt))) * 8.0,
        @cos(@as(f32, @floatCast(dt))) * 8.0,
    ));
    self.pushStack(math.matrix.rotationX(@as(f32, @floatCast(dt)) * -2.0));
    self.pushStack(math.matrix.translate(
        -0.5,
        -0.5,
        -0.5,
    ));
    self.earth_uniform.setUniformMatrix(self.stack[self.current_stack_index]);
    self.popStack(); // remove earth rotation
    self.popStack();
    // moon
    self.pushStack(math.matrix.translate(
        @cos(@as(f32, @floatCast(dt))) * 1.5,
        0,
        @sin(@as(f32, @floatCast(dt))) * 1.5,
    ));
    self.pushStack(math.matrix.rotationY(@as(f32, @floatCast(dt)) * 2.0));
    self.moon_uniform.setUniformMatrix(self.stack[self.current_stack_index]);
    self.resetStack();

    self.view_camera.update(dt);
    {
        const objects: [1]object.object = .{
            self.bg,
        };
        rhi.drawObjects(objects[0..]);
    }
    if (self.sun_texture) |st| {
        st.bind();
    }
    {
        const objects: [1]object.object = .{
            self.sun,
        };
        rhi.drawObjects(objects[0..]);
    }
    if (self.earth_texture) |et| {
        et.bind();
    }
    {
        const objects: [1]object.object = .{
            self.earth,
        };
        rhi.drawObjects(objects[0..]);
    }
    if (self.moon_texture) |mt| {
        mt.bind();
    }
    {
        const objects: [1]object.object = .{
            self.moon,
        };
        rhi.drawObjects(objects[0..]);
    }
    if (self.shuttle_texture) |st| {
        st.bind();
    }
    {
        const objects: [1]object.object = .{
            self.shuttle,
        };
        rhi.drawObjects(objects[0..]);
    }
}

pub fn updateCamera(self: *SimpleSolarSystem) void {
    if (!self.initialized) return;
    var pos = self.view_camera.camera_pos;
    const orientation = self.view_camera.camera_orientation;

    const direction_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(
        physics.camera.world_right,
        orientation,
    ));
    const orientation_vector = math.vector.normalize(
        math.rotation.rotateVectorWithNormalizedQuat(physics.camera.world_up, orientation),
    );
    const left_vector = math.vector.crossProduct(direction_vector, orientation_vector);
    const velocity = math.vector.mul(1.0, left_vector);
    pos = math.vector.add(pos, velocity);
    var m = math.matrix.identity();

    m = math.matrix.transformMatrix(m, math.matrix.translate(pos[0] - 0.5, pos[1], pos[2]));
    const a: math.rotation.AxisAngle = .{
        .angle = std.math.pi,
        .axis = physics.camera.world_up,
    };
    var q = math.rotation.axisAngleToQuat(a);
    q = math.vector.normalize(q);
    q = math.rotation.multiplyQuaternions(orientation, q);
    m = math.matrix.transformMatrix(m, math.matrix.normalizedQuaternionToMatrix(q));
    self.shuttle_uniform.setUniformMatrix(m);
}

pub fn renderSun(self: *SimpleSolarSystem) void {
    self.sun_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    const prog = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .lighting = .blinn_phong,
            .frag_body = texture_frag_shader,
            .fragment_shader = rhi.Texture.frag_shader(self.sun_texture),
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
    }
    const cm = math.matrix.identity();
    const i_data: rhi.instanceData = .{
        .t_column0 = cm.columns[0],
        .t_column1 = cm.columns[1],
        .t_column2 = cm.columns[2],
        .t_column3 = cm.columns[3],
        .color = .{ 1, 0, 1, 1 },
    };
    var i_datas: [num_cubes]rhi.instanceData = undefined;
    for (0..num_cubes) |i| {
        i_datas[i] = i_data;
    }
    const sun: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    if (self.sun_texture) |*bt| {
        bt.setup(self.ctx.textures_loader.loadAsset("cgpoc\\PlanetPixelEmporium\\sunmap.jpg") catch null, prog, "f_samp") catch {
            std.debug.print("didn't load sun\n", .{});
            self.sun_texture = null;
        };
    }
    self.sun = sun;
    self.sun_uniform = rhi.Uniform.init(prog, "f_model_transform");
}

pub fn renderEarth(self: *SimpleSolarSystem) void {
    const prog = rhi.createProgram();
    self.earth_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .lighting = .blinn_phong,
            .frag_body = frag_texture_shader,
            .fragment_shader = rhi.Texture.frag_shader(self.earth_texture),
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(0.75));
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
        i_datas[0] = i_data;
    }
    const earth: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    if (self.earth_texture) |*bt| {
        bt.setup(self.ctx.textures_loader.loadAsset("cgpoc\\PlanetPixelEmporium\\earthmap1k.jpg") catch null, prog, "f_samp") catch {
            self.earth_texture = null;
        };
    }
    self.earth = earth;
    self.earth_uniform = rhi.Uniform.init(prog, "f_model_transform");
}

pub fn renderMoon(self: *SimpleSolarSystem) void {
    self.moon_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    const prog = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .lighting = .blinn_phong,
            .frag_body = frag_texture_shader,
            .fragment_shader = rhi.Texture.frag_shader(self.moon_texture),
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(0.25));
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
        i_datas[0] = i_data;
    }
    const moon: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    if (self.moon_texture) |*bt| {
        bt.setup(self.ctx.textures_loader.loadAsset("cgpoc\\PlanetPixelEmporium\\moon.jpg") catch null, prog, "f_samp") catch {
            self.moon_texture = null;
        };
    }
    self.moon = moon;
    self.moon_uniform = rhi.Uniform.init(prog, "f_model_transform");
}
pub fn renderBG(self: *SimpleSolarSystem) void {
    const prog = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .color,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_static_shader)[0..]);
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.leftHandedXUpToNDC());
        cm = math.matrix.transformMatrix(cm, math.matrix.translate(-1, 0.9999, -3));
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(6));
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 0, 0, 0.0125, 1 },
        };
        i_datas[0] = i_data;
    }
    var bg: object.object = .{
        .instanced_triangle = object.InstancedTriangle.init(
            prog,
            i_datas[0..],
        ),
    };
    bg.instanced_triangle.mesh.cull = false;
    self.bg = bg;
}

pub fn renderShuttle(self: *SimpleSolarSystem) void {
    var shuttle_model: *assets.Obj = undefined;
    if (self.ctx.obj_loader.loadAsset("cgpoc\\NasaShuttle\\shuttle.obj") catch null) |o| {
        std.debug.print("got shuttle\n", .{});
        shuttle_model = o;
    } else {
        std.debug.print("no shuttle\n", .{});
        return;
    }

    const prog = rhi.createProgram();
    self.shuttle_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .lighting = .blinn_phong,
            .frag_body = frag_texture_shader,
            .xup = .wavefront,
            .fragment_shader = rhi.Texture.frag_shader(self.shuttle_texture),
        };
        const partials = [_][]const u8{vertex_shader};
        s.attach(self.allocator, @ptrCast(partials[0..]));
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(0.5));
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
        i_datas[0] = i_data;
    }
    if (self.shuttle_texture) |*bt| {
        bt.setup(self.ctx.textures_loader.loadAsset("cgpoc\\NasaShuttle\\spstob_1.jpg") catch null, prog, "f_samp") catch {
            self.shuttle_texture = null;
        };
    }
    const shuttle_object: object.object = shuttle_model.toObject(prog, i_datas[0..]);
    self.shuttle_uniform = rhi.Uniform.init(prog, "f_model_transform");
    {
        self.shuttle_uniform.setUniformMatrix(math.matrix.translate(3, 0, 0));
    }
    self.shuttle = shuttle_object;
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const ui = @import("../../../../ui/ui.zig");
const rhi = @import("../../../../rhi/rhi.zig");
const math = @import("../../../../math/math.zig");
const object = @import("../../../../object/object.zig");
const scenes = @import("../../../scenes.zig");
const physics = @import("../../../../physics/physics.zig");
const assets = @import("../../../../assets/assets.zig");
const lighting = @import("../../../../lighting/lighting.zig");
