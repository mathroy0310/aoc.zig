const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

pub fn part1(self: *const @This()) !?i64 {
    return self.solve(2);
}

pub fn part2(self: *const @This()) !?i64 {
    return self.solve(12);
}

fn solve(self: *const @This(), count: usize) !?i64 {
    var total: i64 = 0;
    var line_iter = mem.splitSequence(u8, self.input, "\n");
    while (line_iter.next()) |line| {
        const trimmed = mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0) continue;
        total += findMaxJoltage(trimmed, count);
    }
    return total;
}

fn findMaxJoltage(bank: []const u8, target: usize) i64 {
    var result: i64 = 0;
    var start_pos: usize = 0;
    var picked: usize = 0;

    while (picked < target) {
        var best_digit: u8 = 0;
        var best_pos: usize = start_pos;

        var pos = start_pos;
        while (pos < bank.len) : (pos += 1) {
            const ch = bank[pos];
            if (ch < '0' or ch > '9') continue;

            const remaining_needed = target - picked - 1;
            const remaining_available = countDigitsAfter(bank, pos + 1);

            if (remaining_available >= remaining_needed and ch - '0' > best_digit) {
                best_digit = ch - '0';
                best_pos = pos;
            }
        }

        result = result * 10 + @as(i64, best_digit);
        start_pos = best_pos + 1;
        picked += 1;
    }

    return result;
}

fn countDigitsAfter(bank: []const u8, start: usize) usize {
    var count: usize = 0;
    for (bank[start..]) |ch| {
        if (ch >= '0' and ch <= '9') count += 1;
    }
    return count;
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;
    const problem: @This() = .{ .input = input, .allocator = allocator };
    try std.testing.expectEqual(357, try problem.part1());
    try std.testing.expectEqual(3121910778619, try problem.part2());
}
