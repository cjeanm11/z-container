const std = @import("std");
const syscalls = @import("syscalls.zig");

pub fn main() !void {
    std.debug.print("Starting Zig container...\n", .{});

    try syscalls.unshare(syscalls.CLONE_NEWPID | syscalls.CLONE_NEWNS | syscalls.CLONE_NEWUTS);
    try syscalls.sethostname("zig-container");
    try syscalls.chroot("/home/liz/ubuntufs");
    var dir = try std.fs.cwd().openDir("/", .{});
    defer dir.close();
    try dir.setAsCwd();
    
    try syscalls.create_cgroup("zig-container");
    try syscalls.set_cgroup_limit("zig-container", "memory.max", "512M");
    try syscalls.set_cgroup_limit("zig-container", "cpu.max", "50000 100000");
    try syscalls.set_cgroup_limit("zig-container", "pids.max", "20");
    try syscalls.add_process_to_cgroup("zig-container");

    try syscalls.mount("proc", "/proc", "proc", 0, null);
    
    const args: [*]const ?[*:0]const u8 = &[_]?[*:0]const u8{ "/bin/sh", null };
    const envp: [*]const ?[*:0]const u8 = &[_]?[*:0]const u8{ "PATH=/bin", null };

    try syscalls.execve(args[0].?, args, envp);
}