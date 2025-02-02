const std = @import("std");
const syscalls = @import("syscalls.zig");
const builtin = @import("builtin");

comptime {
    if (builtin.os.tag != .linux) @compileError("This program only supports Linux.");
}

pub fn main() !void {
    std.debug.print("> Starting Zig container...\n", .{});

    try syscalls.unshare(syscalls.CLONE_NEWPID | syscalls.CLONE_NEWNS | syscalls.CLONE_NEWUTS);
    std.debug.print("> Unshared namespaces.\n", .{});

    try syscalls.sethostname("zig-container");
    std.debug.print("> Set hostname.\n", .{});

    try syscalls.chroot("/home/liz/ubuntufs");
    std.debug.print("> Changed root to /home/liz/ubuntufs.\n", .{});

    var dir = try std.fs.cwd().openDir("/", .{});
    defer dir.close();
    try dir.setAsCwd();
    std.debug.print("> Set working directory to new root.\n", .{});

    try syscalls.create_cgroup("zig-container");
    std.debug.print("> Created cgroup.\n", .{});

    try syscalls.set_cgroup_limit("zig-container", "memory.max", "512M");
    try syscalls.set_cgroup_limit("zig-container", "cpu.max", "50000 100000");
    try syscalls.set_cgroup_limit("zig-container", "pids.max", "20");
    try syscalls.add_process_to_cgroup("zig-container");
    std.debug.print("> Cgroup limits applied.\n", .{});

    try syscalls.mount("proc", "/proc", "proc", 0, null);
    std.debug.print("> Mounted proc filesystem.\n", .{});

    const args: [*]const ?[*:0]const u8 = &[_]?[*:0]const u8{ "/bin/sh", null };
    const envp: [*]const ?[*:0]const u8 = &[_]?[*:0]const u8{ "PATH=/bin", null };

    std.debug.print("> Executing: {s}\n", .{args[0].?});
    try syscalls.execve(args[0].?, args, envp);
}