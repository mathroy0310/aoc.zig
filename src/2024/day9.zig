const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Block = i32;
const FREE_SPACE: Block = -1;

fn parseBlocks(allocator: mem.Allocator, input: []const u8) !std.ArrayList(Block) {
    var blocks = try std.ArrayList(Block).initCapacity(allocator, 4096);
    errdefer blocks.deinit(allocator);

    var file_id: Block = 0;
    var is_file = true;

    for (input) |ch| {
        if (!std.ascii.isDigit(ch)) continue;

        const length = ch - '0';
        const block_value: Block = if (is_file) file_id else FREE_SPACE;

        var i: u8 = 0;
        while (i < length) : (i += 1) {
            try blocks.append(allocator, block_value);
        }

        if (is_file) {
            file_id += 1;
        }
        is_file = !is_file;
    }

    return blocks;
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

fn compactBlocks(blocks: []Block) void {
    var left: usize = 0;
    var right: usize = blocks.len - 1;

    while (left < right) {
        while (left < blocks.len and blocks[left] != FREE_SPACE) {
            left += 1;
        }

        while (right > 0 and blocks[right] == FREE_SPACE) {
            right -= 1;
        }

        if (left < right) {
            blocks[left] = blocks[right];
            blocks[right] = FREE_SPACE;
            left += 1;
            right -= 1;
        }
    }
}

const FileInfo = struct {
    start: usize,
    size: usize,
};

fn findFile(blocks: []const Block, file_id: Block) ?FileInfo {
    var file_start: ?usize = null;
    var file_size: usize = 0;

    for (blocks, 0..) |block, pos| {
        if (block == file_id) {
            if (file_start == null) {
                file_start = pos;
            }
            file_size += 1;
        }
    }

    if (file_start) |start| {
        return FileInfo{ .start = start, .size = file_size };
    }
    return null;
}

fn findFreeSpan(blocks: []const Block, required_size: usize, before_pos: usize) ?usize {
    var free_start: ?usize = null;
    var free_size: usize = 0;

    for (blocks[0..before_pos], 0..) |block, pos| {
        if (block == FREE_SPACE) {
            if (free_size == 0) {
                free_start = pos;
            }
            free_size += 1;

            if (free_size >= required_size) {
                return free_start;
            }
        } else {
            free_size = 0;
            free_start = null;
        }
    }

    return null;
}

fn moveFile(blocks: []Block, from: usize, to: usize, size: usize, file_id: Block) void {
    var i: usize = 0;
    while (i < size) : (i += 1) {
        blocks[to + i] = file_id;
        blocks[from + i] = FREE_SPACE;
    }
}

fn compactWholeFiles(blocks: []Block) void {
    var max_file_id: Block = 0;
    for (blocks) |block| {
        if (block != FREE_SPACE and block > max_file_id) {
            max_file_id = block;
        }
    }

    var current_file_id = max_file_id;
    while (current_file_id >= 0) : (current_file_id -= 1) {
        const file_info = findFile(blocks, current_file_id) orelse continue;

        if (findFreeSpan(blocks, file_info.size, file_info.start)) |free_start| {
            moveFile(blocks, file_info.start, free_start, file_info.size, current_file_id);
        }
    }
}

pub fn part1(this: *const @This()) !?u64 {
    var blocks = try parseBlocks(this.allocator, this.input);
    defer blocks.deinit(this.allocator);

    compactBlocks(blocks.items);
    return calculateChecksum(blocks.items);
}

pub fn part2(this: *const @This()) !?u64 {
    var blocks = try parseBlocks(this.allocator, this.input);
    defer blocks.deinit(this.allocator);

    compactWholeFiles(blocks.items);
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
