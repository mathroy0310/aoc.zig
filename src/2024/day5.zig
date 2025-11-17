const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

fn parseRules(allocator: std.mem.Allocator, rules_str: []const u8) !std.AutoArrayHashMap(u8, std.AutoArrayHashMapUnmanaged(u8, void)) {
    var rules = std.AutoArrayHashMap(u8, std.AutoArrayHashMapUnmanaged(u8, void)).init(allocator);

    var rulesit = std.mem.tokenizeScalar(u8, rules_str, '\n');
    while (rulesit.next()) |rulestr| {
        var ruleit = std.mem.tokenizeScalar(u8, rulestr, '|');
        const key = try std.fmt.parseInt(u8, ruleit.next().?, 10);
        const value = try std.fmt.parseInt(u8, ruleit.next().?, 10);
        const gop = try rules.getOrPut(key);
        if (!gop.found_existing) gop.value_ptr.* = .{};
        try gop.value_ptr.putNoClobber(allocator, value, {});
    }
    return rules;
}

fn processUpdates(allocator: std.mem.Allocator, rules: *const std.AutoArrayHashMap(u8, std.AutoArrayHashMapUnmanaged(u8, void)), updates_str: []const u8, _part2: bool) !i64 {
    var counter: i64 = 0;
    var updatesit = std.mem.tokenizeScalar(u8, updates_str, '\n');
    var l = try std.ArrayList(u8).initCapacity(allocator, 512);
    defer l.deinit(allocator);
    while (updatesit.next()) |upstr| {
        // put the updates into a list
        var updit = std.mem.tokenizeScalar(u8, upstr, ',');
        l.clearRetainingCapacity();
        while (updit.next()) |up| try l.append(allocator, try std.fmt.parseInt(u8, up, 10));

        // check order
        const ok = for (l.items[0 .. l.items.len - 1], l.items[1..]) |curr, next| {
            const nexts = rules.get(curr);
            if (nexts == null or nexts.?.get(next) == null) break false;
        } else true;

        if (ok) {
            if (!_part2) {
                counter += l.items[l.items.len / 2];
            }
        } else {
            // out of order. loop swapping first out of order pair until in order
            outer: while (true) {
                for (l.items[0 .. l.items.len - 1], l.items[1..]) |*curr, *next| {
                    const nexts = rules.get(curr.*);
                    if (nexts == null or nexts.?.get(next.*) == null) {
                        std.mem.swap(u8, curr, next);
                        continue :outer;
                    }
                }
                if (_part2) {
                    counter += l.items[l.items.len / 2];
                }
                break;
            }
        }
    }
    return counter;
}

pub fn part1(this: *const @This()) !?i64 {
    var parts = std.mem.tokenizeSequence(u8, this.input, "\n\n");
    const rules_str = parts.next().?;
    const updates_str = parts.next().?;
    var rules = try parseRules(this.allocator, rules_str);
    defer rules.deinit();
    return try processUpdates(this.allocator, &rules, updates_str, false);
}

pub fn part2(this: *const @This()) !?i64 {
    var parts = std.mem.tokenizeSequence(u8, this.input, "\n\n");
    const rules_str = parts.next().?;
    const updates_str = parts.next().?;
    var rules = try parseRules(this.allocator, rules_str);
    defer rules.deinit();
    return try processUpdates(this.allocator, &rules, updates_str, true);
}

test "example" {
    const allocator = std.testing.allocator;
    const input =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(143, try problem.part1());
    try std.testing.expectEqual(123, try problem.part2());
}
