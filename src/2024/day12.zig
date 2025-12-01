const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Point = struct {
    row: i32,
    col: i32,
};

const Region = struct {
    cells: std.ArrayList(Point),
    plant_type: u8,

    fn deinit(self: *Region, allocator: mem.Allocator) void {
        self.cells.deinit(allocator);
    }
};

const DIRECTIONS = [_]Point{
    .{ .row = -1, .col = 0 }, // up
    .{ .row = 1, .col = 0 }, // down
    .{ .row = 0, .col = -1 }, // left
    .{ .row = 0, .col = 1 }, // right
};

pub fn part1(self: *const @This()) !?i64 {
    return self.calculateTotalPrice(false);
}

pub fn part2(self: *const @This()) !?i64 {
    return self.calculateTotalPrice(true);
}

fn calculateTotalPrice(self: *const @This(), use_sides: bool) !?i64 {
    var lines = try std.ArrayList([]const u8).initCapacity(self.allocator, 140); //Il y a 140 lignes dans le input
    defer lines.deinit(self.allocator);

    var line_iter = mem.tokenizeScalar(u8, self.input, '\n');
    while (line_iter.next()) |line| {
        if (line.len > 0) {
            try lines.append(self.allocator, line);
        }
    }

    if (lines.items.len == 0) return null;

    const rows = lines.items.len;
    const cols = lines.items[0].len;

    var visited = try self.allocator.alloc([]bool, rows);
    defer {
        for (visited) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(visited);
    }

    for (0..rows) |i| {
        visited[i] = try self.allocator.alloc(bool, cols);
        @memset(visited[i], false);
    }

    var total_price: i64 = 0;

    for (0..rows) |r| {
        for (0..cols) |c| {
            if (!visited[r][c]) {
                const plant_type = lines.items[r][c];
                var region = try self.findRegion(lines.items, visited, @intCast(r), @intCast(c), plant_type);
                defer region.deinit(self.allocator);

                const area: i64 = @intCast(region.cells.items.len);
                const metric = if (use_sides)
                    try self.countSides(&region, lines.items)
                else
                    self.calculatePerimeter(&region, lines.items);

                total_price += area * metric;
            }
        }
    }

    return total_price;
}

fn findRegion(
    self: *const @This(),
    grid: []const []const u8,
    visited: [][]bool,
    start_row: i32,
    start_col: i32,
    plant_type: u8,
) !Region {
    const rows: i32 = @intCast(grid.len);
    const cols: i32 = @intCast(grid[0].len);

    var cells = try std.ArrayList(Point).initCapacity(self.allocator, 512);
    var queue = try std.ArrayList(Point).initCapacity(self.allocator, 512);
    defer queue.deinit(self.allocator);

    try queue.append(self.allocator, .{ .row = start_row, .col = start_col });
    visited[@intCast(start_row)][@intCast(start_col)] = true;

    while (queue.items.len > 0) {
        const current = queue.orderedRemove(0);
        try cells.append(self.allocator, current);

        for (DIRECTIONS) |dir| {
            const new_row = current.row + dir.row;
            const new_col = current.col + dir.col;

            if (new_row < 0 or new_row >= rows or new_col < 0 or new_col >= cols) {
                continue;
            }

            const ur: usize = @intCast(new_row);
            const uc: usize = @intCast(new_col);

            if (grid[ur][uc] == plant_type and !visited[ur][uc]) {
                visited[ur][uc] = true;
                try queue.append(self.allocator, .{ .row = new_row, .col = new_col });
            }
        }
    }

    return Region{ .cells = cells, .plant_type = plant_type };
}

fn calculatePerimeter(self: *const @This(), region: *const Region, grid: []const []const u8) i64 {
    _ = self;
    const rows: i32 = @intCast(grid.len);
    const cols: i32 = @intCast(grid[0].len);

    var perimeter: i64 = 0;

    for (region.cells.items) |cell| {
        for (DIRECTIONS) |dir| {
            const new_row = cell.row + dir.row;
            const new_col = cell.col + dir.col;

            if (new_row < 0 or new_row >= rows or new_col < 0 or new_col >= cols) {
                perimeter += 1;
            } else {
                const ur: usize = @intCast(new_row);
                const uc: usize = @intCast(new_col);
                if (grid[ur][uc] != region.plant_type) {
                    perimeter += 1;
                }
            }
        }
    }

    return perimeter;
}

fn countSides(self: *const @This(), region: *const Region, grid: []const []const u8) !i64 {
    // Créer un Set pour une recherche rapide
    var cell_set = std.AutoHashMap(Point, void).init(self.allocator);
    defer cell_set.deinit();

    for (region.cells.items) |cell| {
        try cell_set.put(cell, {});
    }

    // Compter les côtés en comptant les coins.
    // Chaque coin contribue au nombre de côtés.
    var corners: i64 = 0;

    for (region.cells.items) |cell| {
        // Vérifier les 4 configurations possibles pour les coins
        // Un coin existe lorsque :
        // 1. Deux arêtes adjacentes sont toutes deux des bordures (coin extérieur)
        // 2. Deux arêtes adjacentes ne sont PAS toutes deux des bordures, mais la diagonale est une bordure (coin intérieur)

        const checks = [_]struct { d1: usize, d2: usize, diag: Point }{
            .{ .d1 = 0, .d2 = 2, .diag = .{ .row = -1, .col = -1 } }, // up-left
            .{ .d1 = 0, .d2 = 3, .diag = .{ .row = -1, .col = 1 } }, // up-right
            .{ .d1 = 1, .d2 = 2, .diag = .{ .row = 1, .col = -1 } }, // down-left
            .{ .d1 = 1, .d2 = 3, .diag = .{ .row = 1, .col = 1 } }, // down-right
        };

        for (checks) |check| {
            const n1 = Point{ .row = cell.row + DIRECTIONS[check.d1].row, .col = cell.col + DIRECTIONS[check.d1].col };
            const n2 = Point{ .row = cell.row + DIRECTIONS[check.d2].row, .col = cell.col + DIRECTIONS[check.d2].col };
            const diag = Point{ .row = cell.row + check.diag.row, .col = cell.col + check.diag.col };

            const has_n1 = cell_set.contains(n1);
            const has_n2 = cell_set.contains(n2);
            const has_diag = cell_set.contains(diag);

            // Coin extérieur : les deux côtés sont des bordures
            if (!has_n1 and !has_n2) {
                corners += 1;
            }
            // Coin intérieur : les deux côtés sont dans la région, mais la diagonale ne l'est pas.
            else if (has_n1 and has_n2 and !has_diag) {
                corners += 1;
            }
        }
    }

    _ = grid;
    return corners;
}
test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\RRRRIICCFF
        \\RRRRIICCCF
        \\VVRRRCCFFF
        \\VVRCCCJFFF
        \\VVVVCJJCFE
        \\VVIVCCJJEE
        \\VVIIICJJEE
        \\MIIIIIJJEE
        \\MIIISIJEEE
        \\MMMISSJEEE
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(1930, try problem.part1());
    try std.testing.expectEqual(1206, try problem.part2());
}
