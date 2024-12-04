const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Pair = struct { isize, isize };

pub fn part1(this: *const @This()) !?i64 {
    const dirs: [8]Pair = [_]Pair{ .{ -1, 0 }, .{ -1, -1 }, .{ -1, 1 }, .{ 1, 0 }, .{ 1, -1 }, .{ 1, 1 }, .{ 0, -1 }, .{ 0, 1 } };
    const WORD = "XMAS";

    var lines_iter = std.mem.tokenizeScalar(u8, this.input, '\n');

    var lines = std.ArrayList([]const u8).init(this.allocator);
    defer lines.deinit();

    while (lines_iter.next()) |line| {
        try lines.append(line);
    }

    var count: i64 = 0;

    for (lines.items, 0..) |r, y| {
        for (r, 0..) |_, x| {
            dir: for (dirs) |p| {
                inline for (0..4) |d| {
                    const yd: isize = @as(isize, @intCast(y)) + p[0] * d;
                    const xd: isize = @as(isize, @intCast(x)) + p[1] * d;

                    if (yd >= 0 and yd < lines.items.len and xd >= 0 and xd < lines.items[y].len) {
                        if (lines.items[@intCast(yd)][@intCast(xd)] != WORD[d]) {
                            continue :dir;
                        }
                    } else {
                        continue :dir;
                    }
                }
                count += 1;
            }
        }
    }
    return count;
}

pub fn part2(this: *const @This()) !?i64 {
    const dirs: [4][2]Pair = [4][2]Pair{
        [2]Pair{ .{ -1, -1 }, .{ 1, 1 } },
        [2]Pair{ .{ -1, 1 }, .{ 1, -1 } },
        [2]Pair{ .{ 1, -1 }, .{ -1, 1 } },
        [2]Pair{ .{ 1, 1 }, .{ -1, -1 } },
    };
    const WORD = "MS";

    var lines_iter = std.mem.tokenizeScalar(u8, this.input, '\n');
    var lines = std.ArrayList([]const u8).init(this.allocator);
    defer lines.deinit();

    while (lines_iter.next()) |row| {
        try lines.append(row);
    }

    var count: i64 = 0;

    for (lines.items, 0..) |r, y| {
        for (r, 0..) |_, x| {
            if (lines.items[y][x] != 'A') {
                continue;
            }

            var point_count: usize = 0;
            dir: for (dirs) |dd| {
                for (dd, 0..) |p, idx| {
                    const yd: isize = @as(isize, @intCast(y)) + p[0];
                    const xd: isize = @as(isize, @intCast(x)) + p[1];

                    if (yd >= 0 and yd < lines.items.len and xd >= 0 and xd < lines.items[y].len) {
                        if (lines.items[@as(usize, @intCast(yd))][@as(usize, @intCast(xd))] != WORD[idx]) {
                            continue :dir;
                        }
                    } else {
                        continue :dir;
                    }
                }
                point_count += 1;
            }
            if (point_count == 2) {
                count += 1;
            }
        }
    }

    return count;
}

test "example" {
    const allocator = std.testing.allocator;
    // const input =
    //     \\....XXMAS.
    //     \\.SAMXMS...
    //     \\...S..A...
    //     \\..A.A.MS.X
    //     \\XMASAMX.MM
    //     \\X.....XA.A
    //     \\S.S.S.S.SS
    //     \\.A.A.A.A.A
    //     \\..M.M.M.MM
    //     \\.X.X.XMASX
    // ;

    const input =
        \\.M.S......
        \\..A..MSMS.
        \\.M.S.MAA..
        \\..A.ASMSM.
        \\.M.S.M....
        \\..........
        \\S.S.S.S.S.
        \\.A.A.A.A..
        \\M.M.M.M.M.
        \\..........
    ;
    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(9, try problem.part1());
    try std.testing.expectEqual(null, try problem.part2());
}
