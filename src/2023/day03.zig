const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?i64 {
    var counter: i64 = 0;

    const linelen = (std.mem.indexOfScalar(u8, this.input, '\n') orelse unreachable) + 1;
    var gears = std.AutoArrayHashMap(usize, [2]usize).init(this.allocator);
    defer gears.deinit();

    var digstart: ?usize = null;
    for (0..this.input.len) |i| {
        const isdig = std.ascii.isDigit(this.input[i]);
        if (digstart == null and isdig) {
            digstart = i;
        } else if (!isdig and digstart != null) { // digit end
            const dig = this.input[digstart.?..i];
            digstart = null;
            const abovei = if (i > linelen) i - linelen else i;
            const belowi = if (i + linelen < this.input.len) i + linelen else i;
            const mnbsym = sym: for ([_]usize{ abovei, i, belowi }) |endi| {
                for ((endi - dig.len) -| 1..endi + 1) |ii| {
                    const c = this.input[ii];
                    if (c != '.' and
                        !std.ascii.isWhitespace(c) and
                        !std.ascii.isDigit(c))
                        break :sym ii;
                }
            } else null;

            if (mnbsym) |symidx| {
                const n = try std.fmt.parseInt(usize, dig, 10);
                counter += @as(i64, @intCast(n));
                if (this.input[symidx] == '*') {
                    const gop = try gears.getOrPut(symidx);
                    if (!gop.found_existing) gop.value_ptr.* = .{ 0, 1 };
                    gop.value_ptr[0] += 1;
                    gop.value_ptr[1] *= n;
                }
            }
        }
    }

    return counter;
}

pub fn part2(this: *const @This()) !?i64 {
    var counter: i64 = 0;

    const linelen = (std.mem.indexOfScalar(u8, this.input, '\n') orelse unreachable) + 1;
    var gears = std.AutoArrayHashMap(usize, [2]usize).init(this.allocator);
    defer gears.deinit();

    var digstart: ?usize = null;
    for (0..this.input.len) |i| {
        const isdig = std.ascii.isDigit(this.input[i]);
        if (digstart == null and isdig) {
            digstart = i;
        } else if (!isdig and digstart != null) { // digit end
            const dig = this.input[digstart.?..i];
            digstart = null;
            const abovei = if (i > linelen) i - linelen else i;
            const belowi = if (i + linelen < this.input.len) i + linelen else i;
            const mnbsym = sym: for ([_]usize{ abovei, i, belowi }) |endi| {
                for ((endi - dig.len) -| 1..endi + 1) |ii| {
                    const c = this.input[ii];
                    if (c != '.' and
                        !std.ascii.isWhitespace(c) and
                        !std.ascii.isDigit(c))
                        break :sym ii;
                }
            } else null;

            if (mnbsym) |symidx| {
                const n = try std.fmt.parseInt(usize, dig, 10);
                if (this.input[symidx] == '*') {
                    const gop = try gears.getOrPut(symidx);
                    if (!gop.found_existing) gop.value_ptr.* = .{ 0, 1 };
                    gop.value_ptr[0] += 1;
                    gop.value_ptr[1] *= n;
                }
            }
        }
    }

    var it = gears.iterator();
    while (it.next()) |e| {
        if (e.value_ptr[0] == 2) counter += @as(i64, @intCast(e.value_ptr.*[1]));
    }

    return counter;
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(4361, try problem.part1());
    try std.testing.expectEqual(467835, try problem.part2());
}
