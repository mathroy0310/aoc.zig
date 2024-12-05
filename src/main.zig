const std = @import("std");
const fs = std.fs;
const io = std.io;
const heap = std.heap;

const Problem = @import("problem");

pub fn main() !void {
    const stdout = io.getStdOut().writer();

    var arena = heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const problem = Problem{
        .input = @embedFile("input"),
        .allocator = allocator,
    };

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
}
