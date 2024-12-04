const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?i64 {
    var lines = std.mem.tokenizeScalar(u8, this.input, '\n');

    var left_list = std.ArrayListUnmanaged(i32){};
    defer left_list.deinit(this.allocator);

    var right_list = std.ArrayListUnmanaged(i32){};
    defer right_list.deinit(this.allocator);

    while (lines.next()) |line| {
        var pair = std.mem.tokenizeScalar(u8, line, ' ');

        const left_item = pair.next().?;
        const left_id = try std.fmt.parseInt(i32, left_item, 10);
        try left_list.append(this.allocator, left_id);

        const right_item = pair.next().?;
        const right_id = try std.fmt.parseInt(i32, right_item, 10);
        try right_list.append(this.allocator, right_id);
    }

    std.mem.sort(i32, left_list.items, {}, std.sort.asc(i32));
    std.mem.sort(i32, right_list.items, {}, std.sort.asc(i32));

    var total_distance: u32 = 0;
    for (left_list.items, right_list.items) |left, right| {
        total_distance += @abs(left - right);
    }

    return total_distance;
}

pub fn part2(this: *const @This()) !?i64 {
    var lines = std.mem.tokenizeScalar(u8, this.input, '\n');

    var left_list = std.ArrayListUnmanaged(i32){};
    defer left_list.deinit(this.allocator);

    var right_list = std.ArrayListUnmanaged(i32){};
    defer right_list.deinit(this.allocator);

    while (lines.next()) |line| {
        var pair = std.mem.tokenizeScalar(u8, line, ' ');

        const left_item = pair.next().?;
        const left_id = try std.fmt.parseInt(i32, left_item, 10);
        try left_list.append(this.allocator, left_id);

        const right_item = pair.next().?;
        const right_id = try std.fmt.parseInt(i32, right_item, 10);
        try right_list.append(this.allocator, right_id);
    }

    std.mem.sort(i32, left_list.items, {}, std.sort.asc(i32));
    std.mem.sort(i32, right_list.items, {}, std.sort.asc(i32));

    var similarity_score: usize = 0;
    for (left_list.items) |left_item| {
        const appearance_count = std.mem.count(i32, right_list.items, &.{left_item});
        similarity_score += @as(usize, @intCast(left_item)) * appearance_count;
    }

    return @as(i64, @intCast(similarity_score));
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(11, try problem.part1());
    try std.testing.expectEqual(31, try problem.part2());
}
