const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

fn possibleNum(input: *const []const u8, i: *usize, delim: u8) !i32 {
    var counter: i32 = 0;
    while (i.* < input.len) {
        const cur = input.*[i.*];
        if (cur == delim) {
            break;
        }
        if (cur < '0' or cur > '9') {
            return -1;
        }
        const num: i32 = @intCast(cur - '0');
        counter *= 10;
        counter += num;
        i.* += 1;
    }
    return counter;
}

pub fn part1(this: *const @This()) !?i64 {
    var counter: i64 = 0;
    var i: usize = 0;
    while (i < this.input.len) {
        if (i >= 3 and std.mem.eql(u8, "mul(", this.input[i - 3 .. i + 1])) {
            i += 1;
            const num1 = try possibleNum(&this.input, &i, ',');
            i += 1;
            if (num1 == -1) {
                continue;
            }
            const num2 = try possibleNum(&this.input, &i, ')');
            i += 1;
            if (num2 == -1) {
                continue;
            }
            counter += num1 * num2;
        }
        i += 1;
    }
    return counter;
}

const search_pattern: [2]u8 = .{ 'd', 'm' };

pub fn part2(this: *const @This()) !?i64 {
    var counter: i32 = 0;
    var i: usize = 0;
    var do: bool = true;
    while (i < this.input.len) {
        if (i >= 3 and std.mem.eql(u8, "do()", this.input[i - 3 .. i + 1])) {
            do = true;
        } else if (i >= 6 and std.mem.eql(u8, "don't()", this.input[i - 6 .. i + 1])) {
            do = false;
        } else if (do and i >= 3 and std.mem.eql(u8, "mul(", this.input[i - 3 .. i + 1])) {
            i += 1;
            const num1 = try possibleNum(&this.input, &i, ',');
            i += 1;
            if (num1 == -1) {
                continue;
            }
            const num2 = try possibleNum(&this.input, &i, ')');
            i += 1;
            if (num2 == -1) {
                continue;
            }
            counter += num1 * num2;
        }
        i += 1;
    }
    return counter;
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(161, try problem.part1());
    try std.testing.expectEqual(48, try problem.part2());
}
