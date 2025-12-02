const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Machine = struct {
    a_x: i64,
    a_y: i64,
    b_x: i64,
    b_y: i64,
    prize_x: i64,
    prize_y: i64,
};

pub fn part1(self: *const @This()) !?i64 {
    var machines = try std.ArrayList(Machine).initCapacity(self.allocator, 512);
    defer machines.deinit(self.allocator);

    try self.parseMachines(&machines);

    var total_tokens: i64 = 0;

    for (machines.items) |machine| {
        if (try findCheapestSolution(machine, 100)) |tokens| {
            total_tokens += tokens;
        }
    }

    return total_tokens;
}

pub fn part2(self: *const @This()) !?i64 {
    var machines = try std.ArrayList(Machine).initCapacity(self.allocator, 512);
    defer machines.deinit(self.allocator);

    try self.parseMachines(&machines);

    var total_tokens: i64 = 0;
    const offset: i64 = 10000000000000;

    for (machines.items) |machine| {
        const adjusted_machine = Machine{
            .a_x = machine.a_x,
            .a_y = machine.a_y,
            .b_x = machine.b_x,
            .b_y = machine.b_y,
            .prize_x = machine.prize_x + offset,
            .prize_y = machine.prize_y + offset,
        };

        if (try solveMachineAlgebraic(adjusted_machine)) |tokens| {
            total_tokens += tokens;
        }
    }

    return total_tokens;
}

fn parseMachines(self: *const @This(), machines: *std.ArrayList(Machine)) !void {
    var lines = mem.tokenizeScalar(u8, self.input, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        if (!mem.startsWith(u8, line, "Button A:")) continue;

        const a_x = try parseNumber(line, "X+");
        const a_y = try parseNumber(line, "Y+");

        // Parse Button B line
        const b_line = lines.next() orelse continue;
        const b_x = try parseNumber(b_line, "X+");
        const b_y = try parseNumber(b_line, "Y+");

        // Parse Prize line
        const p_line = lines.next() orelse continue;
        const prize_x = try parseNumber(p_line, "X=");
        const prize_y = try parseNumber(p_line, "Y=");

        try machines.append(self.allocator, .{
            .a_x = a_x,
            .a_y = a_y,
            .b_x = b_x,
            .b_y = b_y,
            .prize_x = prize_x,
            .prize_y = prize_y,
        });
    }
}

fn parseNumber(line: []const u8, prefix: []const u8) !i64 {
    const start = mem.indexOf(u8, line, prefix) orelse return error.ParseError;
    const start_idx = start + prefix.len;

    var end_idx = start_idx;
    while (end_idx < line.len and (std.ascii.isDigit(line[end_idx]) or line[end_idx] == '-')) {
        end_idx += 1;
    }

    return try std.fmt.parseInt(i64, line[start_idx..end_idx], 10);
}

fn findCheapestSolution(machine: Machine, max_presses: i64) !?i64 {
    // on doit solve :
    // a * a_x + b * b_x = prize_x
    // a * a_y + b * b_y = prize_y
    // Ou a,b sont non-negatif integers <= max_presses
    // et minimize: 3*a + b

    var min_cost: ?i64 = null;

    var a: i64 = 0;
    while (a <= max_presses) : (a += 1) {
        var b: i64 = 0;
        while (b <= max_presses) : (b += 1) {
            const x = a * machine.a_x + b * machine.b_x;
            const y = a * machine.a_y + b * machine.b_y;

            if (x == machine.prize_x and y == machine.prize_y) {
                const cost = 3 * a + b;
                if (min_cost == null or cost < min_cost.?) {
                    min_cost = cost;
                }
            }
        }
    }
    return min_cost;
}

fn solveMachineAlgebraic(machine: Machine) !?i64 {
    // a * a_x + b * b_x = prize_x
    // a * a_y + b * b_y = prize_y
    //
    // Cramer's rule:
    // determinant = a_x * b_y - a_y * b_x
    // a = (prize_x * b_y - prize_y * b_x) / determinant
    // b = (a_x * prize_y - a_y * prize_x) / determinant

    const det = machine.a_x * machine.b_y - machine.a_y * machine.b_x;

    // lignes paralleles
    if (det == 0) return null;

    const a_num = machine.prize_x * machine.b_y - machine.prize_y * machine.b_x;
    const b_num = machine.a_x * machine.prize_y - machine.a_y * machine.prize_x;

    if (@mod(a_num, det) != 0 or @mod(b_num, det) != 0) {
        return null;
    }

    const a = @divExact(a_num, det);
    const b = @divExact(b_num, det);

    // si négatif
    if (a < 0 or b < 0) {
        return null;
    }

    // vérifie solution
    if (a * machine.a_x + b * machine.b_x != machine.prize_x or
        a * machine.a_y + b * machine.b_y != machine.prize_y)
    {
        return null;
    }

    return 3 * a + b;
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\Button A: X+94, Y+34
        \\Button B: X+22, Y+67
        \\Prize: X=8400, Y=5400
        \\
        \\Button A: X+26, Y+66
        \\Button B: X+67, Y+21
        \\Prize: X=12748, Y=12176
        \\
        \\Button A: X+17, Y+86
        \\Button B: X+84, Y+37
        \\Prize: X=7870, Y=6450
        \\
        \\Button A: X+69, Y+23
        \\Button B: X+27, Y+71
        \\Prize: X=18641, Y=10279
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(480, try problem.part1());
    // try std.testing.expectEqual(null, try problem.part2());
}
