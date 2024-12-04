const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

fn count_pattern_with_stride(haystack: []const u8, needle: []const u8, stride: usize) i64 {
    var i: usize = 0;
    var found: i64 = 0;

    outer: while (i < haystack.len - (needle.len - 1) * stride) : (i += 1) {
        for (0.., needle) |j, c| {
            if (haystack[i + j * stride] != c)
                continue :outer;
        }

        found += 1;
    }

    return found;
}

pub fn part1(this: *const @This()) !?i64 {
    const l = std.mem.indexOfScalar(u8, this.input, '\n').? + 1;
    const strides = [_]usize{ 1, l, l - 1, l + 1 };

    var count: i64 = 0;

    for (strides) |stride| {
        count += count_pattern_with_stride(this.input, "XMAS", stride);
        count += count_pattern_with_stride(this.input, "SAMX", stride);
    }

    return count;
}

pub fn part2(this: *const @This()) !?i64 {
    const l = std.mem.indexOfScalar(u8, this.input, '\n').? + 1;

    var count: i64 = 0;

    for (l + 1..this.input.len - l - 1) |i| {
        if (i % l == 0 or i % l == l - 1) continue;
        if (this.input[i] != 'A') continue;

        const c0 = this.input[i - l - 1];
        const c1 = this.input[i + l + 1];
        if (!((c0 == 'M' and c1 == 'S') or (c0 == 'S' and c1 == 'M')))
            continue;

        const c2 = this.input[i - l + 1];
        const c3 = this.input[i + l - 1];
        if (!((c2 == 'M' and c3 == 'S') or (c2 == 'S' and c3 == 'M')))
            continue;

        count += 1;
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

    try std.testing.expectEqual(0, try problem.part1());
    try std.testing.expectEqual(9, try problem.part2());
}
