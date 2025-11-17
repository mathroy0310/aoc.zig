const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

fn countDigits(n: u64) u32 {
    if (n == 0) return 1;
    var count: u32 = 0;
    var num = n;
    while (num > 0) {
        count += 1;
        num /= 10;
    }
    return count;
}

fn splitNumber(n: u64, num_digits: u32) struct { left: u64, right: u64 } {
    const half = num_digits / 2;
    var divisor: u64 = 1;
    var i: u32 = 0;
    while (i < half) : (i += 1) {
        divisor *= 10;
    }
    const left = n / divisor;
    const right = n % divisor;
    return .{
        .left = left,
        .right = right,
    };
}

fn simulateBlinksMemoized(self: *const @This(), num_blinks: u32) !u64 {
    var stones = std.AutoHashMap(u64, u64).init(self.allocator);
    defer stones.deinit();

    // Parse initial stones
    var it = mem.tokenizeScalar(u8, self.input, ' ');
    while (it.next()) |token| {
        const trimmed = mem.trim(u8, token, &std.ascii.whitespace);
        if (trimmed.len > 0) {
            const num = try std.fmt.parseInt(u64, trimmed, 10);
            const count = stones.get(num) orelse 0;
            try stones.put(num, count + 1);
        }
    }

    var i: u32 = 0;
    while (i < num_blinks) : (i += 1) {
        var new_stones = std.AutoHashMap(u64, u64).init(self.allocator);

        var stone_it = stones.iterator();
        while (stone_it.next()) |entry| {
            const stone = entry.key_ptr.*;
            const count = entry.value_ptr.*;

            if (stone == 0) {
                // Rule 1: 0 becomes 1
                const new_count = new_stones.get(1) orelse 0;
                try new_stones.put(1, new_count + count);
            } else {
                const digits = countDigits(stone);
                if (digits % 2 == 0) {
                    // Rule 2: Even number of digits - split
                    const split = splitNumber(stone, digits);

                    const left_count = new_stones.get(split.left) orelse 0;
                    try new_stones.put(split.left, left_count + count);

                    const right_count = new_stones.get(split.right) orelse 0;
                    try new_stones.put(split.right, right_count + count);
                } else {
                    // Rule 3: Multiply by 2024
                    const new_val = stone * 2024;
                    const new_count = new_stones.get(new_val) orelse 0;
                    try new_stones.put(new_val, new_count + count);
                }
            }
        }

        stones.deinit();
        stones = new_stones;
    }

    // Sum all counts
    var total: u64 = 0;
    var stone_it = stones.iterator();
    while (stone_it.next()) |entry| {
        total += entry.value_ptr.*;
    }

    return total;
}

pub fn part1(self: *const @This()) !?i64 {
    return @intCast(try self.simulateBlinksMemoized(25));
}

pub fn part2(self: *const @This()) !?i64 {
    return @intCast(try self.simulateBlinksMemoized(75));
}

test "example" {
    const allocator = std.testing.allocator;
    const input = "125 17";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(55312, try problem.part1());
}

test "count digits" {
    try std.testing.expectEqual(1, countDigits(0));
    try std.testing.expectEqual(1, countDigits(9));
    try std.testing.expectEqual(2, countDigits(10));
    try std.testing.expectEqual(2, countDigits(99));
    try std.testing.expectEqual(3, countDigits(100));
    try std.testing.expectEqual(4, countDigits(1000));
}
