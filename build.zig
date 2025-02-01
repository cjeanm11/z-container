const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.option(std.builtin.Mode, "optimize", "Optimization mode") orelse .Debug;
    const target = b.standardTargetOptions(.{});

    const exe = b.addExecutable(.{
        .name = "zig-container",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.defineCMacro("ZIG_ALLOC_DEBUG", "1");

    b.installArtifact(exe);
}