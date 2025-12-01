const builtin = @import("builtin");
comptime {
    const required_zig = "0.15.1";
    const current_zig = builtin.zig_version;
    const min_zig = std.SemanticVersion.parse(required_zig) catch unreachable;

    if (current_zig.order(min_zig) == .lt) {
        const error_message =
            \\Sorry, it looks like your version of zig is too old. :-(
            \\
            \\aoc.zig requires 0.15.1 build {}
            \\
            \\Please download v0.15.1" build from
            \\
            \\https://ziglang.org/download/
            \\
            \\
        ;
        @compileError(std.fmt.comptimePrint(error_message, .{min_zig}));
    }
}

const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const http = std.http;
const fmt = std.fmt;

const Build = std.Build;
const Step = Build.Step;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const INPUT_DIR = "input";
const SRC_DIR = "src";

const DayConfig = struct {
    year: []const u8,
    day: []const u8,
};

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const day_config = try getDayConfig(b);

    // Build main executable for single day
    const exe = try buildDayExecutable(b, target, optimize, day_config);

    // Setup step
    const setup_step = createSetupStep(b, day_config);
    exe.step.dependOn(setup_step);

    // Install and run steps
    // b.installArtifact(exe);
    const install_artifact = b.addInstallArtifact(exe, .{
        .dest_dir = .{ .override = .{ .custom = day_config.year } },
    });
    b.getInstallStep().dependOn(&install_artifact.step);

    createRunStep(b, exe);

    // Run-all step
    const run_all_step = b.step("run-all", "Run all available days for the year");
    try buildRunAllStep(b, run_all_step, target, optimize, day_config.year);

    // Test step
    try createTestStep(b, target, optimize, day_config, setup_step);

    // Clean step
    createCleanStep(b);
}

fn getDayConfig(b: *Build) !DayConfig {
    const date = timestampToDate(std.time.timestamp(), -5);
    const is_december = date.month == 12;

    const year_option = b.option([]const u8, "year", "The year of the Advent of Code challenge");
    const day_option = b.option([]const u8, "day", "The day of the Advent of Code challenge");

    const is_run_all = isRunAllCommand();

    // Validate: if not in December and not run-all, require both year and day
    if (!is_december and !is_run_all and (year_option == null or day_option == null)) {
        print("\nError: You must specify both -Dyear and -Dday when not in December.\n", .{});
        print("Example: zig build run -Dyear=2024 -Dday=9\n", .{});
        print("For running all days: zig build run-all -Dyear=2024\n\n", .{});
        std.process.exit(1);
    }

    if (is_run_all and day_option != null) {
        print("\nError: You cannot specify -Dday when running all days.\n", .{});
        print("Example: zig build run-all -Dyear=2024\n", .{});
        print("For running one day: zig build run -Dyear=2024 -Dday=9\n\n", .{});
        std.process.exit(1);
    }
    return .{
        .year = year_option orelse try fmt.allocPrint(b.allocator, "{d}", .{date.year}),
        .day = if (day_option) |d| try padDay(b.allocator, d) else try fmt.allocPrint(b.allocator, "{d:0>2}", .{date.day}),
    };
}

fn padDay(allocator: Allocator, day: []const u8) ![]const u8 {
    const day_num = try fmt.parseInt(u8, day, 10);
    return try fmt.allocPrint(allocator, "{d:0>2}", .{day_num});
}

fn isRunAllCommand() bool {
    var args = std.process.args();
    while (args.next()) |arg| {
        if (mem.eql(u8, arg, "run-all")) return true;
    }
    return false;
}

fn buildDayExecutable(
    b: *Build,
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    config: DayConfig,
) !*Build.Step.Compile {
    const exe_name = try fmt.allocPrint(b.allocator, "day{s}", .{config.day});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = exe_name,
        .root_module = exe_mod,
    });

    addConfigOptions(b, exe, config);
    try addProblemImport(b, exe, config);
    try addInputImport(b, exe, config);

    return exe;
}

fn addConfigOptions(b: *Build, exe: *Build.Step.Compile, config: DayConfig) void {
    const options = b.addOptions();
    options.addOption([]const u8, "YEAR", config.year);
    options.addOption([]const u8, "DAY", config.day);
    options.addOption([]const u8, "INPUT_DIR", INPUT_DIR);
    exe.root_module.addOptions("config", options);
}

fn addProblemImport(b: *Build, exe: *Build.Step.Compile, config: DayConfig) !void {
    const problem_path = try buildPath(b.allocator, &.{
        SRC_DIR,
        config.year,
        try fmt.allocPrint(b.allocator, "day{s}.zig", .{config.day}),
    });

    exe.root_module.addAnonymousImport("problem", .{
        .root_source_file = b.path(problem_path),
    });
}

fn addInputImport(b: *Build, exe: *Build.Step.Compile, config: DayConfig) !void {
    const input_path = try buildPath(b.allocator, &.{
        INPUT_DIR,
        config.year,
        try fmt.allocPrint(b.allocator, "day{s}.txt", .{config.day}),
    });

    exe.root_module.addAnonymousImport("input", .{
        .root_source_file = b.path(input_path),
    });
}

fn buildPath(allocator: Allocator, parts: []const []const u8) ![]const u8 {
    return try fs.path.join(allocator, parts);
}

fn createSetupStep(b: *Build, config: DayConfig) *Step {
    const SetupStep = struct {
        step: Step,
        year: []const u8,
        day: []const u8,

        pub fn create(owner: *Build, year: []const u8, day: []const u8) *@This() {
            const self = owner.allocator.create(@This()) catch @panic("OOM");
            self.* = .{
                .step = Step.init(.{
                    .id = .custom,
                    .name = "setup",
                    .owner = owner,
                    .makeFn = make,
                }),
                .year = year,
                .day = day,
            };
            return self;
        }

        fn make(step: *Step, options: Build.Step.MakeOptions) !void {
            _ = options;
            const self: *@This() = @fieldParentPtr("step", step);

            var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            defer arena.deinit();
            const allocator = arena.allocator();

            const day_config = DayConfig{
                .year = self.year,
                .day = self.day,
            };

            try fetchInputFileIfNotPresent(allocator, day_config);
            try generateSourceFileIfNotPresent(allocator, day_config);
        }
    };

    const setup = SetupStep.create(b, config.year, config.day);
    return &setup.step;
}

fn createRunStep(b: *Build, exe: *Build.Step.Compile) void {
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn createTestStep(
    b: *Build,
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    config: DayConfig,
    setup_step: *Step,
) !void {
    const problem_path = try buildPath(b.allocator, &.{
        SRC_DIR,
        config.year,
        try fmt.allocPrint(b.allocator, "day{s}.zig", .{config.day}),
    });

    const problem_test_mod = b.createModule(.{
        .root_source_file = b.path(problem_path),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const problem_unit_tests = b.addTest(.{ .root_module = problem_test_mod });
    const exe_unit_tests = b.addTest(.{ .root_module = exe_mod });

    const run_lib_unit_tests = b.addRunArtifact(problem_unit_tests);
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");

    problem_unit_tests.step.dependOn(setup_step);
    exe_unit_tests.step.dependOn(setup_step);

    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn createCleanStep(b: *Build) void {
    const clean_step = b.step("clean", "Remove build artifacts");
    clean_step.dependOn(&b.addRemoveDirTree(b.path(fs.path.basename(b.install_path))).step);

    if (builtin.os.tag != .windows) {
        clean_step.dependOn(&b.addRemoveDirTree(b.path(".zig-cache")).step);
    }
}

fn buildRunAllStep(
    b: *Build,
    run_all_step: *Step,
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    year: []const u8,
) !void {
    var days = try collectAvailableDays(b.allocator, year);
    defer days.deinit(b.allocator);

    if (days.items.len == 0) {
        print("No source files found for year {s}\n", .{year});
        return;
    }

    var previous_step: ?*Step = null;

    for (days.items) |day_num| {
        const day_str = try fmt.allocPrint(b.allocator, "{d}", .{day_num});
        const config = DayConfig{ .year = year, .day = day_str };

        const day_exe = try buildDayExecutableForRunAll(b, target, optimize, config);

        // Check if input file exists, skip if not
        const input_path = try buildPath(b.allocator, &.{
            INPUT_DIR,
            config.year,
            try fmt.allocPrint(b.allocator, "day{s}.txt", .{config.day}),
        });

        fs.cwd().access(input_path, .{}) catch continue;

        const install_artifact = b.addInstallArtifact(day_exe, .{
            .dest_dir = .{ .override = .{ .custom = year } },
        });

        const run_cmd = b.addRunArtifact(day_exe);
        run_cmd.step.dependOn(&install_artifact.step);

        // Chain steps sequentially
        if (previous_step) |prev| {
            run_cmd.step.dependOn(prev);
        }

        previous_step = &run_cmd.step;
    }

    if (previous_step) |last| {
        run_all_step.dependOn(last);
    }
}

fn buildDayExecutableForRunAll(
    b: *Build,
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    config: DayConfig,
) !*Build.Step.Compile {
    const exe_name = try fmt.allocPrint(b.allocator, "day{s}", .{config.day});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const day_exe = b.addExecutable(.{
        .name = exe_name,
        .root_module = exe_mod,
    });

    addConfigOptions(b, day_exe, config);
    try addProblemImport(b, day_exe, config);

    const input_path = try buildPath(b.allocator, &.{
        INPUT_DIR,
        config.year,
        try fmt.allocPrint(b.allocator, "day{s}.txt", .{config.day}),
    });

    day_exe.root_module.addAnonymousImport("input", .{
        .root_source_file = b.path(input_path),
    });

    return day_exe;
}

fn collectAvailableDays(allocator: Allocator, year: []const u8) !std.ArrayList(u8) {
    const src_year_path = try buildPath(allocator, &.{ SRC_DIR, year });

    var src_dir = fs.cwd().openDir(src_year_path, .{ .iterate = true }) catch |err| {
        if (err == error.FileNotFound) return try std.ArrayList(u8).initCapacity(allocator, 512);
        return err;
    };
    defer src_dir.close();

    var days = try std.ArrayList(u8).initCapacity(allocator, 512);
    var walker = src_dir.iterate();

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;

        const name = entry.name;
        if (!mem.startsWith(u8, name, "day") or !mem.endsWith(u8, name, ".zig")) continue;

        const day_str = name[3 .. name.len - 4];
        const day_num = std.fmt.parseInt(u8, day_str, 10) catch continue;
        try days.append(allocator, day_num);
    }

    std.mem.sort(u8, days.items, {}, std.sort.asc(u8));
    return days;
}

fn fetchInputFileIfNotPresent(allocator: Allocator, config: DayConfig) !void {
    const input_path = try buildPath(allocator, &.{
        INPUT_DIR,
        config.year,
        try fmt.allocPrint(allocator, "day{s}.txt", .{config.day}),
    });

    // If file already exists, return early
    fs.cwd().access(input_path, .{}) catch {
        try fetchFromAocServer(allocator, input_path, config);
    };
}

fn fetchFromAocServer(allocator: Allocator, input_path: []const u8, config: DayConfig) !void {
    const session_token = std.process.getEnvVarOwned(allocator, "AOC_SESSION_TOKEN") catch {
        print("AOC_SESSION_TOKEN environment variable not found, you need to set it to fetch input files from AoC Server.\n", .{});
        return error.EnvironmentVariableNotFound;
    };

    const url = try fmt.allocPrint(
        allocator,
        "https://adventofcode.com/{s}/day/{s}/input",
        .{ config.year, config.day },
    );

    try fs.cwd().makePath(fs.path.dirname(input_path).?);

    var child = std.process.Child.init(&[_][]const u8{
        "curl",
        "-s",
        "-b",
        try fmt.allocPrint(allocator, "session={s}", .{session_token}),
        "-o",
        input_path,
        url,
    }, allocator);

    try child.spawn();
    const term = try child.wait();

    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                print("curl failed with exit code {}\n", .{code});
                print("Failed to fetch input file from AoC Server (Has the problem already been released?).\n", .{});
                return error.FailedToFetchInputFile;
            }
        },
        else => {
            print("curl process terminated abnormally\n", .{});
            return error.FailedToFetchInputFile;
        },
    }
}

fn generateSourceFileIfNotPresent(allocator: Allocator, config: DayConfig) !void {
    const src_path = try buildPath(allocator, &.{
        SRC_DIR,
        config.year,
        try fmt.allocPrint(allocator, "day{s}.zig", .{config.day}),
    });

    // If file already exists, return early
    fs.cwd().access(src_path, .{}) catch {
        try createTemplateFile(src_path);
    };
}

fn createTemplateFile(src_path: []const u8) !void {
    const template =
        \\const std = @import("std");
        \\const mem = std.mem;
        \\
        \\input: []const u8,
        \\allocator: mem.Allocator,
        \\
        \\pub fn part1(self: *const @This()) !?i64 {
        \\    _ = self;
        \\    return null;
        \\}
        \\
        \\pub fn part2(self: *const @This()) !?i64 {
        \\    _ = self;
        \\    return null;
        \\}
        \\
        \\test "example" {
        \\    const allocator = std.testing.allocator;
        \\    const input = "";
        \\
        \\    const problem: @This() = .{
        \\        .input = input,
        \\        .allocator = allocator,
        \\    };
        \\
        \\    try std.testing.expectEqual(null, try problem.part1());
        \\    try std.testing.expectEqual(null, try problem.part2());
        \\}
    ;

    const dir = try fs.cwd().makeOpenPath(fs.path.dirname(src_path).?, .{});
    const file = try dir.createFile(fs.path.basename(src_path), .{});
    defer file.close();
    try file.writeAll(template);
}

// Date/time utilities
inline fn isLeapYear(year: i64) bool {
    return (@mod(year, 4) == 0 and @mod(year, 100) != 0) or (@mod(year, 400) == 0);
}

fn timestampToDate(timestamp: i64, timezoneOffsetHours: i64) struct { year: i64, month: i64, day: i64 } {
    var year: i64 = 1970;
    const secondsInNormalYear: i64 = 31536000;
    const secondsInLeapYear: i64 = 31622400;

    const adjustedTimestamp: i64 = timestamp + timezoneOffsetHours * 3600;

    var remainingSeconds = adjustedTimestamp;
    while (true) {
        const secondsInYear = if (isLeapYear(year)) secondsInLeapYear else secondsInNormalYear;
        if (remainingSeconds < secondsInYear) break;
        remainingSeconds -= secondsInYear;
        year += 1;
    }

    const secondsPerDay: i64 = 24 * 60 * 60;
    var dayOfYear = @as(i64, @divTrunc(remainingSeconds, secondsPerDay)) + 1;
    remainingSeconds = @mod(remainingSeconds, secondsPerDay);

    const daysInMonth: [2][12]u8 = .{
        .{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 },
        .{ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 },
    };

    const leapIndex: usize = if (isLeapYear(year)) 1 else 0;
    var monthIndex: usize = 0;

    while (dayOfYear > @as(i64, daysInMonth[leapIndex][monthIndex])) {
        dayOfYear -= @as(i64, daysInMonth[leapIndex][monthIndex]);
        monthIndex += 1;
    }

    const monthOfYear: i64 = @intCast(monthIndex + 1);
    return .{ .year = year, .month = monthOfYear, .day = dayOfYear };
}
