const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Grid = struct {
    rows: std.ArrayList(std.ArrayList(u8)),
    allocator: mem.Allocator,

    fn init(allocator: mem.Allocator, input: []const u8) !Grid {
        var rows = try std.ArrayList(std.ArrayList(u8)).initCapacity(allocator, 139); // il y a 139 lignes
        var line_iter = mem.splitSequence(u8, input, "\n");
        while (line_iter.next()) |line| {
            const trimmed = mem.trim(u8, line, " \t\r");
            if (trimmed.len == 0) continue;
            var row = try std.ArrayList(u8).initCapacity(allocator, 139); // il y a 139 char par lignes
            try row.appendSlice(allocator, trimmed);
            try rows.append(allocator, row);
        }
        return .{ .rows = rows, .allocator = allocator };
    }

    fn deinit(self: *Grid) void {
        for (self.rows.items) |*row| row.deinit(self.allocator);
        self.rows.deinit(self.allocator);
    }

    fn at(self: *const Grid, row: usize, col: usize) u8 {
        return self.rows.items[row].items[col];
    }

    fn set(self: *Grid, row: usize, col: usize, val: u8) void {
        self.rows.items[row].items[col] = val;
    }

    fn countAdjacent(self: *const Grid, row: usize, col: usize, target: u8) i64 {
        var count: i64 = 0;
        const dirs = [_][2]i32{ .{ -1, 0 }, .{ -1, 1 }, .{ 0, 1 }, .{ 1, 1 }, .{ 1, 0 }, .{ 1, -1 }, .{ 0, -1 }, .{ -1, -1 } };

        for (dirs) |d| {
            const nr = @as(i32, @intCast(row)) + d[0];
            const nc = @as(i32, @intCast(col)) + d[1];
            if (nr < 0 or nr >= self.rows.items.len) continue;
            const r: usize = @intCast(nr);
            if (nc < 0 or nc >= self.rows.items[r].items.len) continue;
            if (self.at(r, @intCast(nc)) == target) count += 1;
        }

        return count;
    }

    fn findAccessible(self: *const Grid, allocator: mem.Allocator) !std.ArrayList([2]usize) {
        var accessible = try std.ArrayList([2]usize).initCapacity(allocator, 8);
        for (self.rows.items, 0..) |row, r| {
            for (row.items, 0..) |cell, c| {
                if (cell == '@' and self.countAdjacent(r, c, '@') < 4) {
                    try accessible.append(allocator, .{ r, c });
                }
            }
        }
        return accessible;
    }
};

pub fn part1(self: *const @This()) !?i64 {
    var grid = try Grid.init(self.allocator, self.input);
    defer grid.deinit();

    var accessible = try grid.findAccessible(self.allocator);
    defer accessible.deinit(self.allocator);

    return @intCast(accessible.items.len);
}

pub fn part2(self: *const @This()) !?i64 {
    var grid = try Grid.init(self.allocator, self.input);
    defer grid.deinit();

    var total: i64 = 0;

    while (true) {
        var accessible = try grid.findAccessible(self.allocator);
        defer accessible.deinit(self.allocator);

        if (accessible.items.len == 0) break;

        for (accessible.items) |pos| {
            grid.set(pos[0], pos[1], '.');
        }

        total += @intCast(accessible.items.len);
    }

    return total;
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(13, try problem.part1());
    try std.testing.expectEqual(43, try problem.part2());
}
