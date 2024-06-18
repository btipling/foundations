program: u32,
vao: u32,
buffer: u32,
count: usize,

const positions: [3][3]f32 = .{
    .{ -1, -1, 0 },
    .{ 1, -1, 0 },
    .{ 0, 0, 0 },
};

const colors: [3][4]f32 = .{
    .{ 0, 1, 0, 1 },
    .{ 0, 0, 1, 1 },
    .{ 1, 0, 0, 1 },
};
