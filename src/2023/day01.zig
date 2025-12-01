const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?i64 {
    var sum: i64 = 0;
    var lines_it = std.mem.tokenizeScalar(u8, this.input, '\n');

    while (lines_it.next()) |line| {
        var firstChar: u8 = 0;
        var secondChar: u8 = 0;
        for (line) |char| {
            if (std.ascii.isDigit(char)) {
                if (firstChar == 0) {
                    firstChar = char - '0';
                }
                secondChar = char - '0';
            }
        }
        sum += (firstChar) * 10 + (secondChar);
    }
    return sum;
}

pub fn part2(this: *const @This()) !?i64 {
    const words = [9][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    var sum: usize = 0;
     var lines_it = std.mem.tokenizeScalar(u8, this.input, '\n');

    while (lines_it.next()) |line| {
        var firstChar: usize = 0;
        var secondChar: usize = 0;
        for (line, 0..) |char, i| {
            if (std.ascii.isDigit(char)) {
                if (firstChar == 0) {
                    firstChar = char - @as(i8, '0');
                }
                secondChar = char - @as(i8, '0');
            } else {
                for (words, 1..) |word, j| {
                    if (i >= word.len - 1) {
                        const extract = line[i + 1 - word.len .. i + 1];
                        if (mem.eql(u8, word, extract)) {
                            if (firstChar == 0) {
                                firstChar = j;
                            }
                            secondChar = j;
                        }
                    }
                }
            }
        }
        // print("firstChar={}, secondChar={}\n", .{ firstChar, secondChar });
        sum += firstChar * 10 + secondChar;
    }
    return @intCast(sum);
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ;
    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(142, try problem.part1());
    try std.testing.expectEqual(281, try problem.part2());
}
