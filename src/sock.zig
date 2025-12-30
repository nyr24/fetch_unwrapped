const std = @import("std");
const linux = std.os.linux;

const IpAddr = [4]u8;

pub const SockAddrIn = extern struct {
    family: u16,
    port: u16,
    addr: IpAddr,
    padding: [16]u8 = undefined,
};

pub fn terminate_and_show_errno(fd: i64) noreturn {
    const errno_r = std.posix.errno(fd);
    std.log.info("errno is: {}", .{errno_r});
    @panic("Error occurred");
}

pub fn sock_create(domain: u32, type_: u32, protocol: u32) i64 {
    const fd: i64 = @intCast(linux.syscall3(.socket, domain, type_, protocol));
    if (fd == -1) {
        terminate_and_show_errno(fd);
    }
    return fd;
}

pub fn sock_bind(fd: i64, sock_addr: *const SockAddrIn, addr_size: u32) bool {
    const status: i64 = @intCast(linux.syscall3(.connect, @intCast(fd), @intFromPtr(sock_addr), addr_size));
    if (status != 0) {
        terminate_and_show_errno(status);
    }
    return status == 0;
}

pub fn sock_connect(fd: i64, sock_addr: *const SockAddrIn, addr_len: u32) usize {
    const fd_usize = @as(usize, @bitCast(fd));
    const addr_usize = @as(usize, @intFromPtr(sock_addr));
    return linux.syscall3(.connect, fd_usize, addr_usize, addr_len);
}

pub fn sock_write(
    fd: i64,
    buff: []const u8,
) usize {
    return linux.syscall3(.write, @bitCast(fd), @intFromPtr(buff.ptr), buff.len);
}

pub fn sock_read(
    fd: i64,
    buff: []u8,
) isize {
    return @bitCast(linux.syscall3(.read, @bitCast(fd), @intFromPtr(buff.ptr), buff.len));
}

pub fn sock_close(fd: i64) void {
    _ = linux.syscall1(.close, @as(usize, @bitCast(fd)));
}
