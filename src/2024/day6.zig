const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Coord = struct { x: usize, y: usize };

const Dir = enum(u2) {
    North = 0,
    East = 1,
    South = 2,
    West = 3,

    fn turnRight(self: Dir) Dir {
        const next: u2 = @truncate((@as(u3, @intFromEnum(self)) + 1) % 4);
        return @enumFromInt(next);
    }
};

fn move(c: Coord, dir: Dir, extent: usize) ?Coord {
    return switch (dir) {
        .North => if (c.y > 0) Coord{ .x = c.x, .y = c.y - 1 } else null,
        .East => if (c.x + 1 < extent) Coord{ .x = c.x + 1, .y = c.y } else null,
        .South => if (c.y + 1 < extent) Coord{ .x = c.x, .y = c.y + 1 } else null,
        .West => if (c.x > 0) Coord{ .x = c.x - 1, .y = c.y } else null,
    };
}

pub fn part1(this: *const @This()) !?i64 {
    var rowsIter = mem.tokenizeScalar(u8, this.input, '\n');
    const extent = mem.indexOfScalar(u8, this.input, '\n') orelse return error.NoNewline;

    const grid_size = extent * extent;
    var visited = try std.DynamicBitSet.initEmpty(this.allocator, grid_size);
    defer visited.deinit();

    var obstacles = try std.DynamicBitSet.initEmpty(this.allocator, grid_size);
    defer obstacles.deinit();

    var foundPos: ?Coord = null;
    var y: usize = 0;

    while (rowsIter.next()) |row| {
        for (row, 0..) |c, x| {
            if (c == '#') {
                obstacles.set(y * extent + x);
            } else if (c == '^') {
                foundPos = .{ .x = x, .y = y };
            }
        }
        y += 1;
    }

    var guardPos = foundPos orelse return error.NoGuardInInput;
    var guardDir: Dir = .North;

    visited.set(guardPos.y * extent + guardPos.x);
    var count: i64 = 1;

    while (move(guardPos, guardDir, extent)) |next| {
        if (obstacles.isSet(next.y * extent + next.x)) {
            guardDir = guardDir.turnRight();
        } else {
            guardPos = next;
            const idx = guardPos.y * extent + guardPos.x;
            if (!visited.isSet(idx)) {
                visited.set(idx);
                count += 1;
            }
        }
    }

    return count;
}

fn detectLoopFast(
    obstacles: *std.DynamicBitSet,
    initialPos: Coord,
    extent: usize,
    visited_states: []u4,
) bool {
    @memset(visited_states, 0);

    var pos = initialPos;
    var dir: Dir = .North;

    const dir_bit: u4 = @as(u4, 1) << @intFromEnum(dir);
    const idx = pos.y * extent + pos.x;
    visited_states[idx] = dir_bit;

    var steps: usize = 0;
    const max_steps = extent * extent * 4;

    while (move(pos, dir, extent)) |next| {
        steps += 1;
        if (steps > max_steps) return true;

        if (obstacles.isSet(next.y * extent + next.x)) {
            dir = dir.turnRight();
        } else {
            pos = next;
            const next_idx = pos.y * extent + pos.x;
            const next_dir_bit: u4 = @as(u4, 1) << @intFromEnum(dir);

            if ((visited_states[next_idx] & next_dir_bit) != 0) {
                return true;
            }
            visited_states[next_idx] |= next_dir_bit;
        }
    }

    return false;
}

pub fn part2(this: *const @This()) !?i64 {
    var rowsIter = mem.tokenizeScalar(u8, this.input, '\n');
    const extent = mem.indexOfScalar(u8, this.input, '\n') orelse return error.NoNewline;
    const grid_size = extent * extent;

    var obstacles = try std.DynamicBitSet.initEmpty(this.allocator, grid_size);
    defer obstacles.deinit();

    var foundPos: ?Coord = null;
    var y: usize = 0;

    while (rowsIter.next()) |row| {
        for (row, 0..) |c, x| {
            if (c == '#') {
                obstacles.set(y * extent + x);
            } else if (c == '^') {
                foundPos = .{ .x = x, .y = y };
            }
        }
        y += 1;
    }

    const initialPos = foundPos orelse return error.NoGuardInInput;

    var path_positions = try std.DynamicBitSet.initEmpty(this.allocator, grid_size);
    defer path_positions.deinit();

    {
        var pos = initialPos;
        var dir: Dir = .North;
        path_positions.set(pos.y * extent + pos.x);

        while (move(pos, dir, extent)) |next| {
            if (obstacles.isSet(next.y * extent + next.x)) {
                dir = dir.turnRight();
            } else {
                pos = next;
                path_positions.set(pos.y * extent + pos.x);
            }
        }
    }

    const visited_states = try this.allocator.alloc(u4, grid_size);
    defer this.allocator.free(visited_states);

    var sum: i64 = 0;

    var iter = path_positions.iterator(.{});
    while (iter.next()) |idx| {
        const test_x = idx % extent;
        const test_y = idx / extent;

        if (test_x == initialPos.x and test_y == initialPos.y) continue;

        if (obstacles.isSet(idx)) continue;

        obstacles.set(idx);

        if (detectLoopFast(&obstacles, initialPos, extent, visited_states)) {
            sum += 1;
        }

        obstacles.unset(idx);
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
