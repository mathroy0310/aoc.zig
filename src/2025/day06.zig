const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Problem = struct {
    numbers: std.ArrayList(i64),
    op: u8,

    fn solve(self: *const Problem) i64 {
        if (self.numbers.items.len == 0) return 0;

        var result = self.numbers.items[0];
        for (self.numbers.items[1..]) |num| {
            if (self.op == '+')
                result += num
            else
                result *= num;
        }
        return result;
    }

    fn deinit(self: *Problem, allocator: mem.Allocator) void {
        self.numbers.deinit(allocator);
    }
};

fn parseWorksheet(self: *const @This()) !std.ArrayList(Problem) {
    var problems = try std.ArrayList(Problem).initCapacity(self.allocator, 128);
    var lines = try std.ArrayList([]const u8).initCapacity(self.allocator, 128);
    defer lines.deinit(self.allocator);

    var line_iter = mem.splitSequence(u8, self.input, "\n");
    while (line_iter.next()) |line| {
        try lines.append(self.allocator, line);
    }

    if (lines.items.len == 0) return problems;

    const width = lines.items[0].len;
    var col: usize = 0;

    while (col < width) {
        var is_empty_col = true;
        for (lines.items) |line| {
            if (col < line.len and line[col] != ' ') {
                is_empty_col = false;
                break;
            }
        }
        if (is_empty_col) {
            col += 1;
            continue;
        }

        var problem_end = col;
        while (problem_end < width) {
            var is_space_col = true;
            for (lines.items) |line| {
                if (problem_end < line.len and line[problem_end] != ' ') {
                    is_space_col = false;
                    break;
                }
            }
            if (is_space_col) break;
            problem_end += 1;
        }

        var numbers = try std.ArrayList(i64).initCapacity(self.allocator, 128);
        var op: u8 = 0;

        for (lines.items) |line| {
            if (col >= line.len) continue;

            const segment = if (problem_end <= line.len) line[col..problem_end] else line[col..];
            const trimmed = mem.trim(u8, segment, " ");

            if (trimmed.len == 1 and (trimmed[0] == '+' or trimmed[0] == '*')) {
                op = trimmed[0];
            } else if (trimmed.len > 0) {
                const num = std.fmt.parseInt(i64, trimmed, 10) catch continue;
                try numbers.append(self.allocator, num);
            }
        }

        if (numbers.items.len > 0 and op != 0) {
            try problems.append(self.allocator, .{ .numbers = numbers, .op = op });
        } else {
            numbers.deinit(self.allocator);
        }
        col = problem_end;
    }

    return problems;
}

pub fn part1(self: *const @This()) !?i64 {
    var problems = try self.parseWorksheet();
    defer {
        for (problems.items) |*p| p.deinit(self.allocator);
        problems.deinit(self.allocator);
    }

    var total: i64 = 0;
    for (problems.items) |*problem| {
        total += problem.solve();
    }

    return total;
}

pub fn part2(self: *const @This()) !?i64 {
    _ = self;
    return null;
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   +  
    ;
    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(4277556, try problem.part1());
    try std.testing.expectEqual(null, try problem.part2());
}
