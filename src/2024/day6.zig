const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

inline fn move(x: u16, y: u16, dir: u2, extent: u16) ?struct { x: u16, y: u16 } {
    return switch (dir) {
        0 => if (y > 0) .{ .x = x, .y = y - 1 } else null, // North
        1 => if (x + 1 < extent) .{ .x = x + 1, .y = y } else null, // East
        2 => if (y + 1 < extent) .{ .x = x, .y = y + 1 } else null, // South
        3 => if (x > 0) .{ .x = x - 1, .y = y } else null, // West
    };
}

pub fn part1(this: *const @This()) !?i64 {
    const extent: u16 = @intCast(mem.indexOfScalar(u8, this.input, '\n') orelse return error.NoNewline);
    const grid_size = @as(usize, extent) * extent;

    var obstacles = try this.allocator.alloc(bool, grid_size);
    defer this.allocator.free(obstacles);
    @memset(obstacles, false);

    var visited = try this.allocator.alloc(bool, grid_size);
    defer this.allocator.free(visited);
    @memset(visited, false);

    var pos_x: u16 = undefined;
    var pos_y: u16 = undefined;
    var parse_y: u16 = 0;
    var idx: usize = 0;

    while (idx < this.input.len) {
        const c = this.input[idx];
        if (c == '\n') {
            parse_y += 1;
            idx += 1;
            continue;
        }

        const x: u16 = @intCast(idx - parse_y * (extent + 1));
        const grid_idx = @as(usize, parse_y) * extent + x;

        if (c == '#') {
            obstacles[grid_idx] = true;
        } else if (c == '^') {
            pos_x = x;
            pos_y = parse_y;
        }

        idx += 1;
    }

    var dir: u2 = 0;
    var count: i64 = 0;

    while (true) {
        const idx_curr = @as(usize, pos_y) * extent + pos_x;
        if (!visited[idx_curr]) {
            visited[idx_curr] = true;
            count += 1;
        }

        const next = move(pos_x, pos_y, dir, extent) orelse break;
        const next_idx = @as(usize, next.y) * extent + next.x;

        if (obstacles[next_idx]) {
            dir = @as(u2, @intCast((@as(u8, dir) + 1) & 3));
        } else {
            pos_x = next.x;
            pos_y = next.y;
        }
    }

    return count;
}

fn detectLoop(
    obstacles: []bool,
    start_x: u16,
    start_y: u16,
    extent: u16,
    visited_states: []u8,
) bool {
    @memset(visited_states, 0);

    var x = start_x;
    var y = start_y;
    var dir: u2 = 0;

    while (true) {
        const idx = @as(usize, y) * extent + x;
        const dir_mask: u8 = @as(u8, 1) << dir;

        if ((visited_states[idx] & dir_mask) != 0) {
            return true;
        }
        visited_states[idx] |= dir_mask;

        const next = move(x, y, dir, extent) orelse return false;
        const next_idx = @as(usize, next.y) * extent + next.x;

        if (obstacles[next_idx]) {
            dir = @as(u2, @intCast((@as(u8, dir) + 1) & 3));
        } else {
            x = next.x;
            y = next.y;
        }
    }
}

pub fn part2(this: *const @This()) !?i64 {
    const extent: u16 = @intCast(mem.indexOfScalar(u8, this.input, '\n') orelse return error.NoNewline);
    const grid_size = @as(usize, extent) * extent;

    var obstacles = try this.allocator.alloc(bool, grid_size);
    defer this.allocator.free(obstacles);
    @memset(obstacles, false);

    var path = try this.allocator.alloc(bool, grid_size);
    defer this.allocator.free(path);
    @memset(path, false);

    const visited_states = try this.allocator.alloc(u8, grid_size);
    defer this.allocator.free(visited_states);

    var initial_x: u16 = undefined;
    var initial_y: u16 = undefined;
    var parse_y: u16 = 0;
    var idx: usize = 0;

    while (idx < this.input.len) {
        const c = this.input[idx];
        if (c == '\n') {
            parse_y += 1;
            idx += 1;
            continue;
        }

        const px: u16 = @intCast(idx - parse_y * (extent + 1));
        const grid_idx = @as(usize, parse_y) * extent + px;

        if (c == '#') {
            obstacles[grid_idx] = true;
        } else if (c == '^') {
            initial_x = px;
            initial_y = parse_y;
        }

        idx += 1;
    }

    // Trace original path
    {
        var x = initial_x;
        var y = initial_y;
        var dir: u2 = 0;
        path[@as(usize, y) * extent + x] = true;

        while (move(x, y, dir, extent)) |next| {
            const next_idx = @as(usize, next.y) * extent + next.x;

            if (obstacles[next_idx]) {
                dir = @as(u2, @intCast((@as(u8, dir) + 1) & 3));
            } else {
                x = next.x;
                y = next.y;
                path[next_idx] = true;
            }
        }
    }

    var sum: i64 = 0;
    const initial_idx = @as(usize, initial_y) * extent + initial_x;

    var test_idx: usize = 0;
    while (test_idx < grid_size) : (test_idx += 1) {
        if (!path[test_idx] or test_idx == initial_idx or obstacles[test_idx]) {
            continue;
        }

        obstacles[test_idx] = true;

        if (detectLoop(obstacles, initial_x, initial_y, extent, visited_states)) {
            sum += 1;
        }

        obstacles[test_idx] = false;
    }

    return sum;
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(41, try problem.part1());
    try std.testing.expectEqual(6, try problem.part2());
}
