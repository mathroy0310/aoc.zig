const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

fn is_safe(levels: []i64) bool {
    if (levels.len == 0) {
        return false;
    }

    var prev = levels[0];

    var incr = false;
    var decr = false;

    for (levels[1..]) |curr| {
        if (@abs(curr - prev) > 3) {
            return false;
        }

        if (curr > prev) {
            if (decr) {
                return false;
            }
            incr = true;
        } else if (curr < prev) {
            if (incr) {
                return false;
            }
            decr = true;
        } else {
            return false;
        }

        prev = curr;
    }

    return true;
}

pub fn part1(this: *const @This()) !?i64 {
    var lines = std.mem.splitScalar(u8, this.input, '\n');
    var counter: i64 = 0;
    while (lines.next()) |line| {
        var levels = std.mem.tokenizeScalar(u8, line, ' ');

        var level = std.ArrayList(i64).init(this.allocator);
        defer level.deinit();
        while (levels.next()) |str| {
            try level.append(try std.fmt.parseInt(i64, str, 10));
        }

        if (is_safe(level.items)) {
            counter += 1;
        }
    }
    return counter;
}

pub fn part2(this: *const @This()) !?i64 {
    var lines = std.mem.splitScalar(u8, this.input, '\n');
    var counter: i64 = 0;
    while (lines.next()) |line| {
        var levels = std.mem.tokenizeScalar(u8, line, ' ');

        var level = std.ArrayList(i64).init(this.allocator);
        defer level.deinit();
        while (levels.next()) |str| {
            try level.append(try std.fmt.parseInt(i64, str, 10));
        }

        if (is_safe(level.items)) {
            counter += 1;
        } else {
            for (0..level.items.len) |i| {
                var dampened_level = try level.clone();
                defer dampened_level.deinit();
                _ = dampened_level.orderedRemove(i);

                if (is_safe(dampened_level.items)) {
                    counter += 1;
                    break;
                }
            }
        }
    }
    return counter;
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(2, try problem.part1());
    try std.testing.expectEqual(4, try problem.part2());
}
