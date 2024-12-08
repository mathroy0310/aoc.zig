const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

fn recursiveSum(slice: []usize, sum: usize, target: usize, is_part2: bool) !?usize {
    if (sum > target) {
        return null;
    }
    if (slice.len == 0) {
        if (sum == target) {
            return sum;
        } else {
            return null;
        }
    }

    if (try recursiveSum(slice[1..], sum + slice[0], target, is_part2)) |total| {
        return total;
    } else if (try recursiveSum(slice[1..], (if (sum == 0) 1 else sum) * slice[0], target, is_part2)) |total| {
        return total;
    }

    if (is_part2) {
        if (sum == 0) {
            const next = slice[0] * try std.math.powi(usize, 10, std.math.log10_int(slice[1]) + 1) + slice[1];
            if (try recursiveSum(slice[2..], next, target, is_part2)) |total| {
                return total;
            }
        } else {
            const next = sum * try std.math.powi(usize, 10, std.math.log10_int(slice[0]) + 1) + slice[0];
            if (try recursiveSum(slice[1..], next, target, is_part2)) |total| {
                return total;
            }
        }
    }
    return null;
}

pub fn part1(this: *const @This()) !?i64 {
    var rowsIter = std.mem.tokenizeScalar(u8, this.input, '\n');
    var total: usize = 0;

    while (rowsIter.next()) |row| {
        var numbersIter = std.mem.tokenizeAny(u8, row, ": ");
        const target = try std.fmt.parseInt(usize, numbersIter.next() orelse return error.InvalidInput, 10);
        var list = std.ArrayList(usize).init(this.allocator);
        defer list.deinit();

        while (numbersIter.next()) |num| {
            const n = try std.fmt.parseInt(usize, num, 10);
            try list.append(n);
        }

        if (try recursiveSum(list.items, 0, target, false)) |_| {
            total += target;
        }
    }

    return @as(i64, @intCast(total));
}

pub fn part2(this: *const @This()) !?i64 {
    var rowsIter = std.mem.tokenizeScalar(u8, this.input, '\n');
    var total: usize = 0;

    while (rowsIter.next()) |row| {
        var numbersIter = std.mem.tokenizeAny(u8, row, ": ");
        const target = try std.fmt.parseInt(usize, numbersIter.next() orelse return error.InvalidInput, 10);
        var list = std.ArrayList(usize).init(this.allocator);
        defer list.deinit();

        while (numbersIter.next()) |num| {
            const n = try std.fmt.parseInt(usize, num, 10);
            try list.append(n);
        }

        if (try recursiveSum(list.items, 0, target, true)) |_| {
            total += target;
        }
    }

    return @as(i64, @intCast(total));
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(3749, try problem.part1());
    try std.testing.expectEqual(11387, try problem.part2());
}
