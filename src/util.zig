const std = @import("std");
const builtin = @import("builtin");
const sock = @import("sock.zig");

pub fn host_to_net(bytes: []u8) void {
    if (builtin.target.cpu.arch.endian() == .little) {
        var i: usize = 0;
        var j: usize = bytes.len - 1;
        while (j > i) {
            const first = bytes.ptr + i;
            const sec = bytes.ptr + j;
            std.mem.swap(u8, @ptrCast(first), @ptrCast(sec));
            i += 1;
            j -= 1;
        }
    }
}

pub fn domain_to_sockaddr(domain: []const u8, comptime required_family: i32) !sock.SockAddrIn {
    var addr_info: ?*std.c.addrinfo = null;
    const res = std.c.getaddrinfo(@ptrCast(domain.ptr), null, null, &addr_info);

    if (addr_info != null and @intFromEnum(res) == 0) {
        while (addr_info) |curr_info| {
            const sock_addr: *sock.SockAddrIn = @ptrCast(curr_info.addr);
            if (sock_addr.family == @as(u16, @intCast(required_family))) {
                return sock_addr.*;
            }
            addr_info = curr_info.next;
        }
    }

    return error.SockAddrAcquireErr;
}
