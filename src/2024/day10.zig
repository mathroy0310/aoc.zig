const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Point = struct {
    row: i32,
    col: i32,
};

fn parseMap(self: *const @This(), input: []const u8) !struct { grid: [][]const u8, rows: usize, cols: usize } {
    var lines = try std.ArrayList([]const u8).initCapacity(self.allocator, 1024);
    var it = mem.tokenizeSequence(u8, input, "\n");
    while (it.next()) |line| {
        if (line.len > 0) {
            try lines.append(self.allocator, line);
        }
    }
    const rows = lines.items.len;
    const cols = if (rows > 0) lines.items[0].len else 0;
    const grid = try lines.toOwnedSlice(self.allocator);
    return .{
        .grid = grid,
        .rows = rows,
        .cols = cols,
    };
}

fn getHeight(grid: [][]const u8, row: i32, col: i32, rows: usize, cols: usize) ?u8 {
    if (row < 0 or col < 0 or row >= rows or col >= cols) return null;
    return grid[@intCast(row)][@intCast(col)];
}

fn countReachableNines(self: *const @This(), grid: [][]const u8, rows: usize, cols: usize, start: Point) !i64 {
    var visited = std.AutoHashMap(Point, void).init(self.allocator);
    defer visited.deinit();

    var reachable_nines = std.AutoHashMap(Point, void).init(self.allocator);
    defer reachable_nines.deinit();

    var queue = try std.ArrayList(Point).initCapacity(self.allocator, 1024);
    defer queue.deinit(self.allocator);

    try queue.append(self.allocator, start);
    try visited.put(start, {});

    const dirs = [_]Point{
        .{ .row = -1, .col = 0 }, // up
        .{ .row = 1, .col = 0 }, // down
        .{ .row = 0, .col = -1 }, // left
        .{ .row = 0, .col = 1 }, // right
    };

    while (queue.items.len > 0) {
        const curr = queue.orderedRemove(0);
        const curr_height = getHeight(grid, curr.row, curr.col, rows, cols) orelse continue;

        // If we reached a 9, record it
        if (curr_height == '9') {
            try reachable_nines.put(curr, {});
            continue;
        }

        // Try all four directions
        for (dirs) |dir| {
            const next = Point{
                .row = curr.row + dir.row,
                .col = curr.col + dir.col,
            };

            if (visited.contains(next)) continue;

            if (getHeight(grid, next.row, next.col, rows, cols)) |next_height| {
                // Check if height increases by exactly 1
                if (next_height == curr_height + 1) {
                    try visited.put(next, {});
                    try queue.append(self.allocator, next);
                }
            }
        }
    }

    return @intCast(reachable_nines.count());
}

fn countDistinctTrails(self: *const @This(), grid: [][]const u8, rows: usize, cols: usize, curr: Point, visited: *std.AutoHashMap(Point, void)) !i64 {
    const curr_height = getHeight(grid, curr.row, curr.col, rows, cols) orelse return 0;

    // If we reached a 9, this is one complete trail
    if (curr_height == '9') {
        return 1;
    }

    // Mark current position as visited
    try visited.put(curr, {});
    defer _ = visited.remove(curr); // Backtrack: unmark when we return

    const dirs = [_]Point{
        .{ .row = -1, .col = 0 }, // up
        .{ .row = 1, .col = 0 }, // down
        .{ .row = 0, .col = -1 }, // left
        .{ .row = 0, .col = 1 }, // right
    };

    var total_trails: i64 = 0;

    // Try all four directions
    for (dirs) |dir| {
        const next = Point{
            .row = curr.row + dir.row,
            .col = curr.col + dir.col,
        };

        // Don't revisit positions in the current path
        if (visited.contains(next)) continue;

        if (getHeight(grid, next.row, next.col, rows, cols)) |next_height| {
            // Check if height increases by exactly 1
            if (next_height == curr_height + 1) {
                total_trails += try self.countDistinctTrails(grid, rows, cols, next, visited);
            }
        }
    }

    return total_trails;
}

pub fn part1(self: *const @This()) !?i64 {
    const map_data = try self.parseMap(self.input);
    defer self.allocator.free(map_data.grid);

    const grid = map_data.grid;
    const rows = map_data.rows;
    const cols = map_data.cols;

    // // Debug: print the grid
    // std.debug.print("\nGrid has {} rows, {} cols\n", .{ rows, cols });
    // for (0..rows) |r| {
    //     std.debug.print("Row {}: '{s}'\n", .{ r, grid[r] });
    // }

    var total_score: i64 = 0;

    // Find all trailheads (height 0) and calculate their scores
    for (0..rows) |r| {
        for (0..cols) |c| {
            if (grid[r][c] == '0') {
                const trailhead = Point{ .row = @intCast(r), .col = @intCast(c) };
                const score = try self.countReachableNines(grid, rows, cols, trailhead);
                total_score += score;
            }
        }
    }

    return total_score;
}

pub fn part2(self: *const @This()) !?i64 {
    const map_data = try self.parseMap(self.input);
    defer self.allocator.free(map_data.grid);

    const grid = map_data.grid;
    const rows = map_data.rows;
    const cols = map_data.cols;

    // // Debug: print the grid
    // std.debug.print("\nGrid has {} rows, {} cols\n", .{ rows, cols });
    // for (0..rows) |r| {
    //     std.debug.print("Row {}: '{s}'\n", .{ r, grid[r] });
    // }

    var total_rating: i64 = 0;

    // Find all trailheads (height 0) and calculate their ratings
    for (0..rows) |r| {
        for (0..cols) |c| {
            if (grid[r][c] == '0') {
                const trailhead = Point{ .row = @intCast(r), .col = @intCast(c) };
                var visited = std.AutoHashMap(Point, void).init(self.allocator);
                defer visited.deinit();
                const rating = try self.countDistinctTrails(grid, rows, cols, trailhead, &visited);
                total_rating += rating;
            }
        }
    }

    return total_rating;
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732 
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(36, try problem.part1());
    try std.testing.expectEqual(81, try problem.part2());
}
