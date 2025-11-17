const std = @import("std");
const heap = std.heap;

const config = @import("config");

const Problem = @import("problem");

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var arena = heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const problem = Problem{
        .input = @embedFile("input"),
        .allocator = allocator,
    };

    try stdout.print("[ADVENT OF CODE] DAY={s}, YEAR={s} \n", .{config.DAY, config.YEAR});
    var timer = try std.time.Timer.start();
    if (try problem.part1()) |solution| {
        const elapsed_ns = timer.read();
        const elapsed_ms: f64 = @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0;

        try stdout.print(switch (@TypeOf(solution)) {
            []const u8 => "[Part 1] result: {s}",
            else => "[Part 1] result: {any} ",
        } ++ "| Took: {d:.4}ms\n", .{ solution, elapsed_ms });
    }
    timer.reset();
    if (try problem.part2()) |solution| {
        const elapsed_ns = timer.read();
        const elapsed_ms: f64 = @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0;
        try stdout.print(switch (@TypeOf(solution)) {
            []const u8 => "[Part 2] result: {s}",
            else => "[Part 2] result: {any}",
        } ++ " | Took: {d:.4}ms\n", .{ solution, elapsed_ms });
    }

    try stdout.flush();
}
