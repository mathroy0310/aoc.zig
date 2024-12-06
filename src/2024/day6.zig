const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const bufcap: usize = 50;

const Coord = struct { x: usize, y: usize };

fn move(c: Coord, dir: Dir, extent: usize) ?Coord {
    switch (dir) {
        .North => {
            if (c.y > 0) {
                return .{ .x = c.x, .y = c.y - 1 };
            }
        },
        .East => {
            if (c.x + 1 < extent) {
                return .{ .x = c.x + 1, .y = c.y };
            }
        },
        .South => {
            if (c.y + 1 < extent) {
                return .{ .x = c.x, .y = c.y + 1 };
            }
        },
        .West => {
            if (c.x > 0) {
                return .{ .x = c.x - 1, .y = c.y };
            }
        },
    }
    return null;
}

const Dir = enum { North, South, East, West };

pub fn part1(this: *const @This()) !?i64 {
    var visited = std.AutoArrayHashMap(Coord, void).init(this.allocator);
    defer visited.deinit();
    var map = std.AutoArrayHashMap(Coord, u8).init(this.allocator);
    defer map.deinit();

    var rowsIter = std.mem.tokenizeScalar(u8, this.input, '\n');

    const extent = std.mem.indexOfScalar(u8, this.input, '\n') orelse return error.NoNewline;

    var foundPos: ?Coord = null;
    var guardDir: Dir = .North;

    var y: usize = 0;
    while (rowsIter.next()) |row| {
        for (row, 0..) |c, x| {
            if (c == '#') {
                try map.putNoClobber(.{ .x = x, .y = y }, c);
            } else if (c == '^') {
                foundPos = .{ .x = x, .y = y };
            }
        }
        y += 1;
    }

    var guardPos = foundPos orelse return error.NoGuardInInput;
    try visited.put(guardPos, {});

    while (move(guardPos, guardDir, extent)) |next| {
        if (map.get(next)) |_| {
            guardDir = switch (guardDir) {
                .North => .East,
                .East => .South,
                .South => .West,
                .West => .North,
            };
        } else {
            guardPos = next;
            try visited.put(next, {});
        }
    }

    return @as(i64, @intCast(visited.count()));
}

fn detect_loop(map: std.AutoArrayHashMap(Coord, void), initialGuardPos: Coord, extent: usize, visited: *std.AutoArrayHashMap(Coord, Dir)) !bool {
    var guardDir: Dir = .North;
    var guardPos: Coord = initialGuardPos;

    try visited.put(guardPos, guardDir);

    while (move(guardPos, guardDir, extent)) |next| {
        if (visited.get(next)) |prevDir| {
            if (prevDir == guardDir) {
                return true;
            }
        }
        if (map.get(next)) |_| {
            guardDir = switch (guardDir) {
                .North => .East,
                .East => .South,
                .South => .West,
                .West => .North,
            };
        } else {
            guardPos = next;
            try visited.put(next, guardDir);
        }
    }

    return false;
}

pub fn part2(this: *const @This()) !?i64 {
    var map = std.AutoArrayHashMap(Coord, void).init(this.allocator);

    var rowsIter = std.mem.tokenizeScalar(u8, this.input, '\n');

    const extent = std.mem.indexOfScalar(u8, this.input, '\n') orelse return error.NoNewline;

    var foundPos: ?Coord = null;
    {
        var y: usize = 0;
        while (rowsIter.next()) |row| {
            for (row, 0..) |c, x| {
                if (c == '#') {
                    try map.putNoClobber(.{ .x = x, .y = y }, {});
                } else if (c == '^') {
                    foundPos = .{ .x = x, .y = y };
                }
            }
            y += 1;
        }
    }

    const initialGuardPos = foundPos orelse return error.NoGuardInInput;
    var visited = std.AutoArrayHashMap(Coord, void).init(this.allocator);
    defer visited.deinit();
    var local_visited = std.AutoArrayHashMap(Coord, Dir).init(this.allocator);
    defer local_visited.deinit();

    {
        var guardPos = initialGuardPos;
        var guardDir: Dir = .North;
        try visited.put(guardPos, {});

        while (move(guardPos, guardDir, extent)) |next| {
            if (map.get(next)) |_| {
                guardDir = switch (guardDir) {
                    .North => .East,
                    .East => .South,
                    .South => .West,
                    .West => .North,
                };
            } else {
                guardPos = next;
                try visited.put(next, {});
            }
        }
    }

    var sum: i64 = 0;
    var iter = visited.iterator();

    while (iter.next()) |entry| {
        const pos = entry.key_ptr;
        if (initialGuardPos.x == pos.x and initialGuardPos.y == pos.y) {
            continue;
        } else if (map.get(pos.*)) |_| {
            continue;
        } else {
            try map.putNoClobber(pos.*, {});
            defer _ = map.swapRemove(pos.*);
            defer local_visited.clearRetainingCapacity();

            if (try detect_loop(map, initialGuardPos, extent, &local_visited)) {
                sum += 1;
            }
        }
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
    try std.testing.expectEqual(null, try problem.part2());
}
