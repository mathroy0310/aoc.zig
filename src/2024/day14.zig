const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Robot = struct {
    px: i64,
    py: i64,
    vx: i64,
    vy: i64,
};

pub fn part1(self: *const @This()) !?i64 {
    return self.calculateSafetyFactor(101, 103, 100);
}

pub fn part2(self: *const @This()) !?i64 {
    _ = self;
    return null;
}

fn calculateSafetyFactor(self: *const @This(), width: i64, height: i64, seconds: i64) !?i64 {
    var robots = try std.ArrayList(Robot).initCapacity(self.allocator, 128);
    defer robots.deinit(self.allocator);

    try self.parseRobots(&robots);

    var final_positions = try std.ArrayList(struct { x: i64, y: i64 }).initCapacity(self.allocator, 128);
    defer final_positions.deinit(self.allocator);

    for (robots.items) |robot| {
        var final_x = robot.px + robot.vx * seconds;
        var final_y = robot.py + robot.vy * seconds;

        final_x = @mod(final_x, width);
        final_y = @mod(final_y, height);

        try final_positions.append(self.allocator, .{ .x = final_x, .y = final_y });
    }

    const mid_x = @divTrunc(width, 2);
    const mid_y = @divTrunc(height, 2);

    var q1: i64 = 0; // top-left
    var q2: i64 = 0; // top-right
    var q3: i64 = 0; // bottom-left
    var q4: i64 = 0; // bottom-right

    for (final_positions.items) |pos| {
        // Skip robots au milieu
        if (pos.x == mid_x or pos.y == mid_y) continue;

        if (pos.x < mid_x and pos.y < mid_y) {
            q1 += 1;
        } else if (pos.x > mid_x and pos.y < mid_y) {
            q2 += 1;
        } else if (pos.x < mid_x and pos.y > mid_y) {
            q3 += 1;
        } else if (pos.x > mid_x and pos.y > mid_y) {
            q4 += 1;
        }
    }

    return q1 * q2 * q3 * q4;
}

fn parseRobots(self: *const @This(), robots: *std.ArrayList(Robot)) !void {
    var lines = mem.tokenizeScalar(u8, self.input, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        // Parse p=x,y v=x,y
        var parts = mem.tokenizeScalar(u8, line, ' ');
        const p_part = parts.next() orelse continue;
        const v_part = parts.next() orelse continue;

        // Parse position: p=x,y
        const p_coords = p_part[2..]; // Skip "p="
        var p_split = mem.splitScalar(u8, p_coords, ',');
        const px = try std.fmt.parseInt(i64, p_split.next() orelse continue, 10);
        const py = try std.fmt.parseInt(i64, p_split.next() orelse continue, 10);

        // Parse velocity: v=x,y
        const v_coords = v_part[2..]; // Skip "v="
        var v_split = mem.splitScalar(u8, v_coords, ',');
        const vx = try std.fmt.parseInt(i64, v_split.next() orelse continue, 10);
        const vy = try std.fmt.parseInt(i64, v_split.next() orelse continue, 10);

        try robots.append(self.allocator, .{
            .px = px,
            .py = py,
            .vx = vx,
            .vy = vy,
        });
    }
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\p=0,4 v=3,-3
        \\p=6,3 v=-1,-3
        \\p=10,3 v=-1,2
        \\p=2,0 v=2,-1
        \\p=0,0 v=1,3
        \\p=3,0 v=-2,-2
        \\p=7,6 v=-1,-3
        \\p=3,0 v=-1,-2
        \\p=9,3 v=2,3
        \\p=7,3 v=-1,2
        \\p=2,4 v=2,-3
        \\p=9,5 v=-3,-3
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };
    _ = problem;
    // try std.testing.expectEqual(12, try problem.part1());
    // try std.testing.expectEqual(null, try problem.part2());
}
