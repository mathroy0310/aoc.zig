const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

pub fn part1(self: *const @This()) !?i64 {
    var sum: i64 = 0;

    var range_iter = mem.splitSequence(u8, self.input, ",");
    while (range_iter.next()) |range_str| {
        const trimmed = mem.trim(u8, range_str, " \t\n\r"); // c'Est une ligne mais juste pour etre sur

        var dash_iter = mem.splitSequence(u8, trimmed, "-");
        const start_str = dash_iter.next() orelse continue;
        const end_str = dash_iter.next() orelse continue;

        const start = try std.fmt.parseInt(i64, start_str, 10);
        const end = try std.fmt.parseInt(i64, end_str, 10);

        var num = start;
        while (num <= end) : (num += 1) {
            if (isInvalidID(num, true)) {
                sum += num;
            }
        }
    }
    return sum;
}

pub fn part2(self: *const @This()) !?i64 {
    var sum: i64 = 0;

    var range_iter = mem.splitSequence(u8, self.input, ",");
    while (range_iter.next()) |range_str| {
        const trimmed = mem.trim(u8, range_str, " \t\n\r"); // c'Est une ligne mais juste pour etre sur

        var dash_iter = mem.splitSequence(u8, trimmed, "-");
        const start_str = dash_iter.next() orelse continue;
        const end_str = dash_iter.next() orelse continue;

        const start = try std.fmt.parseInt(i64, start_str, 10);
        const end = try std.fmt.parseInt(i64, end_str, 10);

        var num = start;
        while (num <= end) : (num += 1) {
            if (isInvalidID(num, false)) {
                sum += num;
            }
        }
    }
    return sum;
}

fn isInvalidID(num: i64, isPart1: bool) bool {
    var buf: [32]u8 = undefined;
    const str = std.fmt.bufPrint(&buf, "{d}", .{num}) catch return false;

    if (isPart1) {

        // doit etre longeur pair pour etre egale
        if (str.len % 2 != 0) return false;

        const half = str.len / 2;
        const first_half = str[0..half];
        const second_half = str[half..];

        return mem.eql(u8, first_half, second_half);
    } else {
        var pattern_len: usize = 1;
        while (pattern_len <= str.len / 2) : (pattern_len += 1) {
            if (str.len % pattern_len != 0) continue;

            const repeats = str.len / pattern_len;
            if (repeats < 2) continue;

            // Check if the entire string is this pattern repeated
            const pattern = str[0..pattern_len];
            var valid = true;
            var i: usize = pattern_len;
            while (i < str.len) : (i += pattern_len) {
                const segment = str[i .. i + pattern_len];
                if (!mem.eql(u8, pattern, segment)) {
                    valid = false;
                    break;
                }
            }

            if (valid) return true;
        }
        return false;
    }
}

test "example" {
    const allocator = std.testing.allocator;
    const input = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(1227775554, try problem.part1());
    try std.testing.expectEqual(4174379265, try problem.part2());
}
