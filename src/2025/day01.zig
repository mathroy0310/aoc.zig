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
        const start_pos = position;

        if (rotation.direction == 'L') {
            // Gauche
            position = position - rotation.distance;
            position = @mod(@mod(position, 100) + 100, 100);
            zero_count += countZeroCrossings(start_pos, rotation.distance, true);
        } else {
            // Droite
            position = position + rotation.distance;
            const final_pos = @mod(position, 100);
            zero_count += countZeroCrossings(start_pos, rotation.distance, false);
            position = final_pos;
        }
    }

    return zero_count;
}

fn countZeroCrossings(start: i32, distance: i32, going_left: bool) i64 {
    var count: i64 = 0;
    const complete_laps = @divFloor(distance, 100);
    count += complete_laps;

    const remaining = @mod(distance, 100);
    
    if (going_left) {
        if (start < remaining) {
            count += 1;
        }
    } else {
        if (start + remaining >= 100) {
            count += 1;
        }
    }

    return count;
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
