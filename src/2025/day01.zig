const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Rotation = struct {
    direction: u8, // 'L' ou 'R'
    distance: i32,
};

pub fn part1(self: *const @This()) !?i64 {
    var rotations = try std.ArrayList(Rotation).initCapacity(self.allocator, 512);
    defer rotations.deinit(self.allocator);

    var line_iter = mem.tokenizeScalar(u8, self.input, '\n');
    while (line_iter.next()) |line| {
        if (line.len < 2) continue;

        const direction = line[0];
        const distance = try std.fmt.parseInt(i32, line[1..], 10);
        try rotations.append(self.allocator, .{ .direction = direction, .distance = distance });
    }

    var position: i32 = 50;
    var zero_count: i64 = 0;

    for (rotations.items) |rotation| {
        if (rotation.direction == 'L') {
            // gauche
            position = position - rotation.distance;
            position = @mod(@mod(position, 100) + 100, 100);
        } else {
            // droite
            position = position + rotation.distance;
            position = @mod(position, 100);
        }

        if (position == 0) {
            zero_count += 1;
        }
    }

    return zero_count;
}

pub fn part2(self: *const @This()) !?i64 {
    var rotations = try std.ArrayList(Rotation).initCapacity(self.allocator, 512);
    defer rotations.deinit(self.allocator);

    var line_iter = mem.tokenizeScalar(u8, self.input, '\n');
    while (line_iter.next()) |line| {
        if (line.len < 2) continue;

        const direction = line[0];
        const distance = try std.fmt.parseInt(i32, line[1..], 10);
        try rotations.append(self.allocator, .{ .direction = direction, .distance = distance });
    }

    var position: i32 = 50;
    var zero_count: i64 = 0;

    for (rotations.items) |rotation| {
        var clicks_remaining = rotation.distance;

        while (clicks_remaining > 0) : (clicks_remaining -= 1) {
            if (rotation.direction == 'L') {
                position -= 1;
                if (position < 0) {
                    position = 99;
                }
            } else {
                position += 1;
                if (position >= 100) {
                    position = 0;
                }
            }

            if (position == 0) {
                zero_count += 1;
            }
        }
    }

    return zero_count;
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(3, try problem.part1());
    try std.testing.expectEqual(6, try problem.part2());
}
