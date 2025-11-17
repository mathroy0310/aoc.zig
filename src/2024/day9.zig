const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Block = i32;
const FREE_SPACE: Block = -1;

const FileSpan = struct {
    id: Block,
    start: usize,
    len: usize,
};

const FreeSpan = struct {
    start: usize,
    len: usize,
};

fn parseInput(this: *const @This(), blocks: *std.ArrayList(Block), files: *std.ArrayList(FileSpan)) !void {
    var file_id: Block = 0;
    var is_file = true;
    var pos: usize = 0;

    for (this.input) |ch| {
        if (!std.ascii.isDigit(ch)) continue;

        const length = ch - '0';

        if (is_file and length > 0) {
            try files.append(this.allocator, .{ .id = file_id, .start = pos, .len = length });

            var i: u8 = 0;
            while (i < length) : (i += 1) {
                try blocks.append(this.allocator, file_id);
            }
            file_id += 1;
            pos += length;
        } else {
            var i: u8 = 0;
            while (i < length) : (i += 1) {
                try blocks.append(this.allocator, FREE_SPACE);
            }
            pos += length;
        }

        is_file = !is_file;
    }
}

fn calculateChecksum(blocks: []const Block) u64 {
    var checksum: u64 = 0;
    for (blocks, 0..) |block, pos| {
        if (block != FREE_SPACE) {
            checksum += pos * @as(u64, @intCast(block));
        }
    }
    return checksum;
}

pub fn part1(this: *const @This()) !?u64 {
    var blocks = try std.ArrayList(Block).initCapacity(this.allocator, 128);
    defer blocks.deinit(this.allocator);
    var files = try std.ArrayList(FileSpan).initCapacity(this.allocator, 128);
    defer files.deinit(this.allocator);

    try this.parseInput(&blocks, &files);

    var left: usize = 0;
    var right: usize = blocks.items.len;

    while (left < right) {
        while (left < right and blocks.items[left] != FREE_SPACE) {
            left += 1;
        }
        
        while (left < right) {
            right -= 1;
            if (blocks.items[right] != FREE_SPACE) {
                break;
            }
        }

        if (left < right) {
            blocks.items[left] = blocks.items[right];
            blocks.items[right] = FREE_SPACE;
        }
    }

    return calculateChecksum(blocks.items);
}

pub fn part2(this: *const @This()) !?u64 {
    var blocks = try std.ArrayList(Block).initCapacity(this.allocator, 128);
    defer blocks.deinit(this.allocator);
    var files = try std.ArrayList(FileSpan).initCapacity(this.allocator, 128);
    defer files.deinit(this.allocator);

    try this.parseInput(&blocks, &files);

    var free_spans = try std.ArrayList(FreeSpan).initCapacity(this.allocator, 128);
    defer free_spans.deinit(this.allocator);

    {
        var i: usize = 0;
        while (i < blocks.items.len) {
            if (blocks.items[i] == FREE_SPACE) {
                const start = i;
                var len: usize = 0;
                while (i < blocks.items.len and blocks.items[i] == FREE_SPACE) {
                    len += 1;
                    i += 1;
                }
                try free_spans.append(this.allocator, .{ .start = start, .len = len });
            } else {
                i += 1;
            }
        }
    }

    var file_idx = files.items.len;
    while (file_idx > 0) {
        file_idx -= 1;
        const file = files.items[file_idx];

        for (free_spans.items, 0..) |*free_span, span_idx| {
            if (free_span.start >= file.start) break;

            if (free_span.len >= file.len) {
                var i: usize = 0;
                while (i < file.len) : (i += 1) {
                    blocks.items[free_span.start + i] = file.id;
                    blocks.items[file.start + i] = FREE_SPACE;
                }

                free_span.start += file.len;
                free_span.len -= file.len;

                if (free_span.len == 0) {
                    _ = free_spans.orderedRemove(span_idx);
                }

                break;
            }
        }
    }

    return calculateChecksum(blocks.items);
}

test "example" {
    const allocator = std.testing.allocator;
    const input = "2333133121414131402";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(1928, try problem.part1());
    try std.testing.expectEqual(2858, try problem.part2());
}
