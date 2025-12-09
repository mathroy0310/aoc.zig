const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Point3D = struct {
    x: i64,
    y: i64,
    z: i64,

    fn distanceSquared(self: Point3D, other: Point3D) i64 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        const dz = self.z - other.z;
        return dx * dx + dy * dy + dz * dz;
    }
};

const Box = struct {
    circuit: usize,
    pos: Point3D,
};

const Edge = struct {
    from: usize,
    to: usize,
    dist_sq: i64,
};

pub fn part1(self: *const @This()) !?i64 {
    return try self.solve(1000);
}

pub fn part2(self: *const @This()) !?i64 {
    return try self.solve2();
}

fn parsePoints(self: @This()) ![]Box {
    var boxes = try std.ArrayList(Box).initCapacity(self.allocator, 512);
    errdefer boxes.deinit(self.allocator);

    var line_iter = mem.tokenizeScalar(u8, self.input, '\n');
    while (line_iter.next()) |line| {
        var num_iter = mem.tokenizeScalar(u8, line, ',');

        const x = try std.fmt.parseInt(i64, num_iter.next() orelse continue, 10);
        const y = try std.fmt.parseInt(i64, num_iter.next() orelse continue, 10);
        const z = try std.fmt.parseInt(i64, num_iter.next() orelse continue, 10);

        try boxes.append(self.allocator, Box{ .circuit = 0, .pos = Point3D{ .x = x, .y = y, .z = z } });
    }

    return boxes.toOwnedSlice(self.allocator);
}

fn compareEdges(_: void, a: Edge, b: Edge) bool {
    return a.dist_sq < b.dist_sq;
}

fn compareCircuitDesc(_: void, a: std.ArrayList(usize), b: std.ArrayList(usize)) bool {
    return a.items.len > b.items.len;
}

fn solve(self: @This(), max_edges: usize) !i64 {
    var boxes = try self.parsePoints();
    defer self.allocator.free(boxes);

    if (boxes.len == 0) return 0;

    var edges = try std.ArrayList(Edge).initCapacity(self.allocator, (boxes.len * (boxes.len - 1)) / 2);
    defer edges.deinit(self.allocator);

    for (0..boxes.len) |i| {
        for (i + 1..boxes.len) |j| {
            const dist_sq = boxes[i].pos.distanceSquared(boxes[j].pos);
            try edges.append(self.allocator, Edge{ .from = i, .to = j, .dist_sq = dist_sq });
        }
    }

    std.mem.sort(Edge, edges.items, {}, compareEdges);

    var circuits = try std.ArrayList(std.ArrayList(usize)).initCapacity(self.allocator, 512);
    defer circuits.deinit(self.allocator);

    const edges_to_process = @min(max_edges, edges.items.len);

    for (edges.items[0..edges_to_process]) |edge| {
        var bx1 = edge.from;
        var bx2 = edge.to;
        var b1 = &boxes[bx1];
        var b2 = &boxes[bx2];

        if (b2.circuit < b1.circuit) {
            std.mem.swap(*Box, &b1, &b2);
            std.mem.swap(usize, &bx1, &bx2);
        }

        if (b1.circuit == 0 and b2.circuit > 0) {
            b1.circuit = b2.circuit;
            try circuits.items[b2.circuit - 1].append(self.allocator, bx1);
        } else if (b1.circuit == 0 and b2.circuit == 0) {
            var new_circuit = try std.ArrayList(usize).initCapacity(self.allocator, 512);
            try new_circuit.append(self.allocator, bx1);
            try new_circuit.append(self.allocator, bx2);
            const circuit_id = circuits.items.len + 1;
            b1.circuit = circuit_id;
            b2.circuit = circuit_id;
            try circuits.append(self.allocator, new_circuit);
        } else if (b1.circuit == b2.circuit) {
            continue;
        } else {
            const c1_idx = b1.circuit - 1;
            const c2_idx = b2.circuit - 1;

            for (circuits.items[c2_idx].items) |box_id| {
                boxes[box_id].circuit = b1.circuit;
                try circuits.items[c1_idx].append(self.allocator, box_id);
            }

            circuits.items[c2_idx].clearRetainingCapacity();
        }
    }

    std.mem.sort(std.ArrayList(usize), circuits.items, {}, compareCircuitDesc);

    const result: i64 = @intCast(circuits.items[0].items.len * circuits.items[1].items.len * circuits.items[2].items.len);
    return result;
}

fn solve2(self: @This()) !i64 {
    var boxes = try self.parsePoints();
    defer self.allocator.free(boxes);

    if (boxes.len == 0) return 0;

    var edges = try std.ArrayList(Edge).initCapacity(self.allocator, (boxes.len * (boxes.len - 1)) / 2);
    defer edges.deinit(self.allocator);

    for (0..boxes.len) |i| {
        for (i + 1..boxes.len) |j| {
            const dist_sq = boxes[i].pos.distanceSquared(boxes[j].pos);
            try edges.append(self.allocator, Edge{ .from = i, .to = j, .dist_sq = dist_sq });
        }
    }

    std.mem.sort(Edge, edges.items, {}, compareEdges);

    var circuits = try std.ArrayList(std.ArrayList(usize)).initCapacity(self.allocator, 512);
    defer circuits.deinit(self.allocator);

    for (edges.items) |edge| {
        var bx1 = edge.from;
        var bx2 = edge.to;
        var b1 = &boxes[bx1];
        var b2 = &boxes[bx2];

        if (b2.circuit < b1.circuit) {
            std.mem.swap(*Box, &b1, &b2);
            std.mem.swap(usize, &bx1, &bx2);
        }

        if (b1.circuit == 0 and b2.circuit > 0) {
            const c2_idx = b2.circuit - 1;
            b1.circuit = b2.circuit;
            try circuits.items[c2_idx].append(self.allocator, bx1);

            if (circuits.items[c2_idx].items.len == boxes.len) {
                return b1.pos.x * b2.pos.x;
            }
        } else if (b1.circuit == 0 and b2.circuit == 0) {
            var new_circuit = try std.ArrayList(usize).initCapacity(self.allocator, 512);
            try new_circuit.append(self.allocator, bx1);
            try new_circuit.append(self.allocator, bx2);
            const circuit_id = circuits.items.len + 1;
            b1.circuit = circuit_id;
            b2.circuit = circuit_id;
            try circuits.append(self.allocator, new_circuit);
        } else if (b1.circuit == b2.circuit) {
            continue;
        } else {
            const c1_idx = b1.circuit - 1;
            const c2_idx = b2.circuit - 1;

            for (circuits.items[c2_idx].items) |box_id| {
                boxes[box_id].circuit = b1.circuit;
                try circuits.items[c1_idx].append(self.allocator, box_id);
            }

            if (circuits.items[c1_idx].items.len == boxes.len) {
                return b1.pos.x * b2.pos.x;
            }

            circuits.items[c2_idx].clearRetainingCapacity();
        }
    }

    return error.NoSolution;
}

// test "example" {
//     const allocator = std.testing.allocator;
//     const input =
//         \\162,817,812
//         \\57,618,57
//         \\906,360,560
//         \\592,479,940
//         \\352,342,300
//         \\466,668,158
//         \\542,29,236
//         \\431,825,988
//         \\739,650,466
//         \\52,470,668
//         \\216,146,977
//         \\819,987,18
//         \\117,168,530
//         \\805,96,715
//         \\346,949,466
//         \\970,615,88
//         \\941,993,340
//         \\862,61,35
//         \\984,92,344
//         \\425,690,689
//     ;

//     const problem: @This() = .{
//         .input = input,
//         .allocator = allocator,
//     };

//     try std.testing.expectEqual(40, try problem.part1());
//     try std.testing.expectEqual(null, try problem.part2());
// }
