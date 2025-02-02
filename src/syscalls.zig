const std = @import("std");
const linux = std.os.linux;
const builtin = @import("builtin");


pub const CLONE_NEWPID = linux.CLONE.NEWPID;
pub const CLONE_NEWNS = linux.CLONE.NEWNS;
pub const CLONE_NEWUTS = linux.CLONE.NEWUTS;

pub fn sethostname(name: [*:0]const u8) !void {
    const len = std.mem.len(name);
    const result = linux.syscall2(.sethostname, @intFromPtr(name), len);
    if (result == -1) return error.HostnameFailed;
}

pub fn unshare(flags: u32) !void {
    const result = linux.unshare(flags);
    if (result == -1) return error.UnshareFailed;
}

pub fn execve(path: [*:0]const u8, argv: [*]const ?[*:0]const u8, envp: [*]const ?[*:0]const u8) !void {
    const result = linux.syscall3(.execve, @intFromPtr(path), @intFromPtr(argv), @intFromPtr(envp));
    if (result == -1) return error.ExecFailed;
}

pub fn chroot(path: [*:0]const u8) !void {
    const result = linux.chroot(path);
    if (result == -1) return error.ChrootFailed;
}

pub fn mount(source: [*:0]const u8, target: [*:0]const u8, fstype: [*:0]const u8, flags: u32, data: ?*const anyopaque) !void {
    const data_ptr: usize = @intFromPtr(data);
    const result = linux.syscall5(.mount, @intFromPtr(source), @intFromPtr(target), @intFromPtr(fstype), flags, data_ptr);
    if (result == -1) return error.MountFailed;
}

pub fn umount(target: [*:0]const u8, flags: c_int) !void {
    const result = linux.umount2(target, flags);
    if (result == -1) return error.UmountFailed;
}

pub fn create_cgroup(name: [*:0]const u8) !void {
    const base_paths = [_][]const u8{ "/sys/fs/cgroup", "/sys/fs/cgroup/user.slice", "/tmp/cgroup" };
    
    var base_path: ?[]const u8 = null;
    
    for (base_paths) |path| {
        if (std.fs.cwd().makePath(path) catch |err| err == error.ReadOnlyFileSystem) {
            continue;
        }
        base_path = path;
        break;
    }

    if (base_path == null) {
        return error.CgroupUnavailable;
    }

    const path = try std.fmt.allocPrint(std.heap.page_allocator, "{s}/{s}", .{ base_path.?, name });
    defer std.heap.page_allocator.free(path);

    try std.fs.cwd().makePath(path);
}

pub fn set_cgroup_limit(cgroup: [*:0]const u8, file: [*:0]const u8, value: []const u8) !void {
    const path = try std.fmt.allocPrint(std.heap.page_allocator, "/sys/fs/cgroup/{s}/{s}", .{cgroup, file});
    defer std.heap.page_allocator.free(path);

    var file_handle = try std.fs.cwd().openFile(path, .{ .mode = .write_only });
    defer file_handle.close();

    try file_handle.writeAll(value);
}

pub fn add_process_to_cgroup(cgroup: [*:0]const u8) !void {
    const path = try std.fmt.allocPrint(std.heap.page_allocator, "/sys/fs/cgroup/{s}/cgroup.procs", .{cgroup});
    defer std.heap.page_allocator.free(path);

    var file_handle = try std.fs.cwd().openFile(path, .{ .mode = .write_only });
    defer file_handle.close();

    const pid = try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{std.os.linux.getpid()});
    defer std.heap.page_allocator.free(pid);

    try file_handle.writeAll(pid);
}