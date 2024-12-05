const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

fn colourToIndex(colour: []const u8) usize {
    return switch (colour[0]) {
        'r' => 0,
        'g' => 1,
        'b' => 2,
        else => std.debug.panic("{s} was an unexpected input", .{colour}),
    };
}

pub fn part1(this: *const @This()) !?i64 {
    var line_it = std.mem.tokenizeScalar(u8, this.input, '\n');

    var sum: u32 = 0;

    while (line_it.next()) |line| {
        var set_it = std.mem.tokenizeAny(u8, line, ";:");
        const game_num = blk: {
            var game_it = std.mem.tokenizeScalar(u8, set_it.next().?, ' ');
            std.debug.assert(std.mem.eql(u8, game_it.next().?, "Game"));
            break :blk try std.fmt.parseInt(u32, game_it.next().?, 10);
        };
        var valid: bool = true;

        while (set_it.next()) |set| {
            var totals: [3]u8 = .{ 0, 0, 0 };
            var it = std.mem.tokenizeAny(u8, set, " ,");
            while (it.next()) |num_str| {
                const count = try std.fmt.parseInt(u8, num_str, 10);
                const colour_idx = colourToIndex(it.next().?);
                totals[colour_idx] += count;
            }
            valid = valid and (totals[0] <= 12) and (totals[1] <= 13) and (totals[2] <= 14);
        }
        if (valid) sum += game_num;
    }
    return sum;
}

pub fn part2(this: *const @This()) !?i64 {
    var line_it = std.mem.tokenizeScalar(u8, this.input, '\n');
    var sum: u32 = 0;
    while (line_it.next()) |line| {
        var set_it = std.mem.tokenizeAny(u8, line, ";:");
        const game_num = blk: {
            var game_it = std.mem.tokenizeScalar(u8, set_it.next().?, ' ');
            std.debug.assert(std.mem.eql(u8, game_it.next().?, "Game"));
            break :blk try std.fmt.parseInt(u32, game_it.next().?, 10);
        };
        _ = game_num;
        var totals: [3]u32 = .{ 0, 0, 0 };

        while (set_it.next()) |set| {
            var it = std.mem.tokenizeAny(u8, set, " ,");
            while (it.next()) |num_str| {
                const count = try std.fmt.parseInt(u8, num_str, 10);
                const colour_idx = colourToIndex(it.next().?);
                totals[colour_idx] = @max(totals[colour_idx], count);
            }
        }
        sum += totals[0] * totals[1] * totals[2];
    }
    return sum;
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(8, try problem.part1());
    try std.testing.expectEqual(2286, try problem.part2());
}
