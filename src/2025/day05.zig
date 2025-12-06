const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Range = struct {
    start: i64,
    end: i64,

    fn contains(self: Range, id: i64) bool {
        return id >= self.start and id <= self.end;
    }

    fn len(self: Range) i64 {
        return self.end - self.start + 1;
    }
};

pub fn part1(self: *const @This()) !?i64 {
    var ranges = try self.parseRanges();
    defer ranges.deinit(self.allocator);

    var section_iter = mem.splitSequence(u8, self.input, "\n\n");
    _ = section_iter.next();
    const ids_section = section_iter.next() orelse return 0;

    var fresh_count: i64 = 0;
    var id_iter = mem.splitSequence(u8, ids_section, "\n");
    while (id_iter.next()) |line| {
        const trimmed = mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;
        const id = try std.fmt.parseInt(i64, trimmed, 10);

        for (ranges.items) |range| {
            if (range.contains(id)) {
                fresh_count += 1;
                break;
            }
        }
    }

    return fresh_count;
}

pub fn part2(self: *const @This()) !?i64 {
    var ranges = try self.parseRanges();
    defer ranges.deinit(self.allocator);

    var merged = try self.mergeRanges(ranges.items);
    defer merged.deinit(self.allocator);

    var total: i64 = 0;
    for (merged.items) |range| {
        total += range.len();
    }

    return total;
}

fn parseRanges(self: *const @This()) !std.ArrayList(Range) {
    var ranges = try std.ArrayList(Range).initCapacity(self.allocator, 64);

    var section_iter = mem.splitSequence(u8, self.input, "\n\n");
    const ranges_section = section_iter.next() orelse return ranges;

    var line_iter = mem.splitSequence(u8, ranges_section, "\n");
    while (line_iter.next()) |line| {
        const trimmed = mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0) continue;

        var dash_iter = mem.splitSequence(u8, trimmed, "-");
        const start_str = dash_iter.next() orelse continue;
        const end_str = dash_iter.next() orelse continue;

        const start = try std.fmt.parseInt(i64, start_str, 10);
        const end = try std.fmt.parseInt(i64, end_str, 10);
        try ranges.append(self.allocator, Range{ .start = start, .end = end });
    }

    return ranges;
}

fn mergeRanges(self: *const @This(), ranges: []Range) !std.ArrayList(Range) {
    if (ranges.len == 0) return try std.ArrayList(Range).initCapacity(self.allocator, 64);

    std.mem.sort(Range, ranges, {}, struct {
        fn lessThan(_: void, a: Range, b: Range) bool {
            return a.start < b.start;
        }
    }.lessThan);

    var merged = try std.ArrayList(Range).initCapacity(self.allocator, 64);
    try merged.append(self.allocator, ranges[0]);

    for (ranges[1..]) |range| {
        var last = &merged.items[merged.items.len - 1];
        if (range.start <= last.end + 1) {
            last.end = @max(last.end, range.end);
        } else {
            try merged.append(self.allocator, range);
        }
    }

    return merged;
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;
    const problem: @This() = .{ .input = input, .allocator = allocator };
    try std.testing.expectEqual(3, try problem.part1());
    try std.testing.expectEqual(14, try problem.part2());
}
