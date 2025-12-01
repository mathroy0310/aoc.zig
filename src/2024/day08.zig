const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Coord = struct { x: isize, y: isize };

pub fn part1(this: *const @This()) !?isize {
    var rowsIter = std.mem.tokenizeScalar(u8, this.input, '\n');
    const extent = std.mem.indexOfScalar(u8, this.input, '\n') orelse return error.InvalidInput;
    var antiNodePoints = std.AutoHashMap(Coord, void).init(this.allocator);
    defer antiNodePoints.deinit();
    var frequencies = std.AutoHashMap(u8, std.ArrayListUnmanaged(Coord)).init(this.allocator);
    defer frequencies.deinit();

    var y: isize = 0;
    while (rowsIter.next()) |row| {
        for (row, 0..) |c, x| {
            if (c == '.') {
                continue;
            }

            var entry = try frequencies.getOrPut(c);

            if (!entry.found_existing) {
                entry.value_ptr.* = try std.ArrayListUnmanaged(Coord).initCapacity(this.allocator, 0);
                try entry.value_ptr.ensureTotalCapacity(this.allocator, 1000);
            }
            try entry.value_ptr.append(this.allocator, .{ .x = @intCast(x), .y = y });
        }
        y += 1;
    }

    var freqIter = frequencies.iterator();

    while (freqIter.next()) |e| {
        defer e.value_ptr.*.deinit(this.allocator);
        const slice = e.value_ptr.items;

        for (slice, 0..) |p1, i| {
            for (slice[(i + 1)..]) |p2| {
                const dx = p1.x - p2.x;
                const dy = p1.y - p2.y;

                const x1 = p1.x + dx;
                const y1 = p1.y + dy;

                const x2 = p2.x - dx;
                const y2 = p2.y - dy;

                if (x1 >= 0 and x1 < extent and y1 >= 0 and y1 < extent) {
                    try antiNodePoints.put(.{ .x = x1, .y = y1 }, {});
                }

                if (x2 >= 0 and x2 < extent and y2 >= 0 and y2 < extent) {
                    try antiNodePoints.put(.{ .x = x2, .y = y2 }, {});
                }
            }
        }
    }

    return antiNodePoints.count();
}

pub fn part2(this: *const @This()) !?isize {
    var rowsIter = std.mem.tokenizeScalar(u8, this.input, '\n');
    const extent = std.mem.indexOfScalar(u8, this.input, '\n') orelse return error.InvalidInput;
    var antiNodePoints = std.AutoHashMap(Coord, void).init(this.allocator);
    defer antiNodePoints.deinit();
    var frequencies = std.AutoHashMap(u8, std.ArrayListUnmanaged(Coord)).init(this.allocator);
    defer frequencies.deinit();

    var y: isize = 0;
    while (rowsIter.next()) |row| {
        for (row, 0..) |c, x| {
            if (c == '.') {
                continue;
            }

            var entry = try frequencies.getOrPut(c);

            if (!entry.found_existing) {
                entry.value_ptr.* = try std.ArrayListUnmanaged(Coord).initCapacity(this.allocator, 0);
                try entry.value_ptr.ensureTotalCapacity(this.allocator, 1000);
            }
            try entry.value_ptr.append(this.allocator, .{ .x = @intCast(x), .y = y });
        }
        y += 1;
    }

    var freqIter = frequencies.iterator();

    while (freqIter.next()) |e| {
        defer e.value_ptr.*.deinit(this.allocator);
        const slice = e.value_ptr.items;

        for (slice, 0..) |p1, i| {
            for (slice[(i + 1)..]) |p2| {
                const dx = p1.x - p2.x;
                const dy = p1.y - p2.y;

                var addedPoints = true;
                var d: isize = 0;

                while (addedPoints) {
                    addedPoints = false;
                    const x1 = p1.x + (dx * d);
                    const y1 = p1.y + (dy * d);

                    const x2 = p2.x - (dx * d);
                    const y2 = p2.y - (dy * d);

                    if (x1 >= 0 and x1 < extent and y1 >= 0 and y1 < extent) {
                        try antiNodePoints.put(.{ .x = x1, .y = y1 }, {});
                        addedPoints = true;
                    }

                    if (x2 >= 0 and x2 < extent and y2 >= 0 and y2 < extent) {
                        try antiNodePoints.put(.{ .x = x2, .y = y2 }, {});
                        addedPoints = true;
                    }

                    d += 1;
                }
            }
        }
    }

    return antiNodePoints.count();
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(14, try problem.part1());
    try std.testing.expectEqual(34, try problem.part2());
}
