const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Point = struct {
    row: usize,
    col: usize,

    fn hash(self: Point) u64 {
        return @as(u64, @intCast(self.row)) << 32 | @as(u64, @intCast(self.col));
    }
};

pub fn part1(self: *const @This()) !?i64 {
    const grid = try self.parseGrid();
    defer self.allocator.free(grid);

    if (grid.len == 0) return 0;

    const start = findStart(grid) orelse return 0;

    return try self.simulateBeams(grid, start);
}

pub fn part2(self: *const @This()) !?i64 {
    const grid = try self.parseGrid();
    defer self.allocator.free(grid);

    if (grid.len == 0) return 0;

    const start = findStart(grid) orelse return 0;

    return try self.countTimelines(grid, start);
}

fn parseGrid(self: @This()) ![][]const u8 {
    var lines = try std.ArrayList([]const u8).initCapacity(self.allocator, 150);
    errdefer lines.deinit(self.allocator);

    var line_iter = mem.tokenizeScalar(u8, self.input, '\n');
    while (line_iter.next()) |line| {
        try lines.append(self.allocator, line);
    }

    return lines.toOwnedSlice(self.allocator);
}

fn findStart(grid: [][]const u8) ?Point {
    for (grid, 0..) |row, r| {
        for (row, 0..) |cell, c| {
            if (cell == 'S') {
                return Point{ .row = @intCast(r), .col = @intCast(c) };
            }
        }
    }
    return null;
}

fn simulateBeams(self: @This(), grid: [][]const u8, start: Point) !i64 {
    var split_count: i64 = 0;

    var beams = std.AutoHashMap(Point, void).init(self.allocator);
    defer beams.deinit();

    try beams.put(start, {});

    var y: usize = 0;
    while (y < grid.len - 1) : (y += 1) {
        var beam_positions = try std.ArrayList(Point).initCapacity(self.allocator, 1024);
        defer beam_positions.deinit(self.allocator);

        var it = beams.keyIterator();
        while (it.next()) |pos| {
            if (pos.row == y) {
                try beam_positions.append(self.allocator, pos.*);
            }
        }

        for (beam_positions.items) |pos| {
            const x = pos.col;
            const next_y = y + 1;

            if (next_y < grid.len and x < grid[next_y].len) {
                const cell_below = grid[next_y][x];
                if (cell_below == '^') {
                    // split en 2
                    split_count += 1;
                    // beam gauche
                    if (x > 0) try beams.put(Point{ .row = next_y, .col = x - 1 }, {});
                    // beam droit
                    if (x + 1 < grid[next_y].len) try beams.put(Point{ .row = next_y, .col = x + 1 }, {});
                } else {
                    // vide S - beam continu down
                    try beams.put(Point{ .row = next_y, .col = x }, {});
                }
            }
        }
    }

    return split_count;
}

fn countTimelines(self: @This(), grid: [][]const u8, start: Point) !i64 {
    var paths = std.AutoHashMap(usize, i64).init(self.allocator);
    defer paths.deinit();

    try paths.put(start.col, 1);

    var y: usize = start.row;
    while (y < grid.len) : (y += 1) {
        var current_paths = try std.ArrayList(struct { x: usize, count: i64 }).initCapacity(self.allocator, 1024);
        defer current_paths.deinit(self.allocator);

        var it = paths.iterator();
        while (it.next()) |entry| {
            try current_paths.append(self.allocator, .{ .x = entry.key_ptr.*, .count = entry.value_ptr.* });
        }

        for (current_paths.items) |path| {
            const x = path.x;
            const path_count = path.count;
            if (y < grid.len and x < grid[y].len and grid[y][x] == '^') {
                if (x > 0) {
                    const gop = try paths.getOrPut(x - 1);
                    if (gop.found_existing) {
                        gop.value_ptr.* += path_count;
                    } else {
                        gop.value_ptr.* = path_count;
                    }
                }
                if (x + 1 < grid[y].len) {
                    const gop = try paths.getOrPut(x + 1);
                    if (gop.found_existing) {
                        gop.value_ptr.* += path_count;
                    } else {
                        gop.value_ptr.* = path_count;
                    }
                }
                try paths.put(x, 0);
            }
        }
    }

    var total: i64 = 0;
    var it = paths.valueIterator();
    while (it.next()) |count| {
        total += count.*;
    }

    return total;
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(21, try problem.part1());
    try std.testing.expectEqual(40, try problem.part2());
}
