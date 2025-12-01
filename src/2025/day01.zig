const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

pub fn part1(self: *const @This()) !?i64 {
    _ = self;
    return null;
}

pub fn part2(self: *const @This()) !?i64 {
    _ = self;
    return null;
}

test "example" {
    const allocator = std.testing.allocator;
    const input = "";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(null, try problem.part1());
    try std.testing.expectEqual(null, try problem.part2());
}