const std = @import("std");
const mem = std.mem;
const linux = std.os.linux;
const sock = @import("sock.zig");
const util = @import("util.zig");
const http = @import("http.zig");
const Request = @import("request.zig").Request;
const builtin = @import("builtin");

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const args = try std.process.argsAlloc(alloc);
    if (args.len < 4) {
        return error.NotEnoughArgs;
    }

    const method_s = args[1];
    const domain = args[2];
    const path = args[3];
    var port: u16 = @intFromEnum(http.Port.HTTP);
    var sock_addr = try util.domain_to_sockaddr(domain, linux.AF.INET);
    util.host_to_net(@ptrCast(@alignCast(&port)));
    sock_addr.port = port;

    const fd = sock.sock_create(linux.AF.INET, linux.SOCK.STREAM, 0);
    defer sock.sock_close(fd);
    _ = sock.sock_bind(fd, &sock_addr, @sizeOf(sock.SockAddrIn));
    _ = sock.sock_connect(fd, &sock_addr, @sizeOf(sock.SockAddrIn));

    var req = try Request.init(alloc, .HTTP10, .from_str(method_s), domain, path, null);
    defer req.deinit(alloc);
    try req.set_header(alloc, .init("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"));
    try req.set_header(alloc, .init("Accept-Language", "en-US,en;q=0.5"));
    try req.set_header(alloc, .init("Accept-Encoding", "gzip, deflate, br, zstd"));

    var cookies: [3]http.Cookie = undefined;
    cookies[0] = http.Cookie.init("cookie1", "val1");
    cookies[1] = http.Cookie.init("cookie2", "val2");
    cookies[2] = http.Cookie.init("cookie3", "val3");
    try req.set_cookies(alloc, cookies[0..]);
    try req.set_header(alloc, .init("Connection", "close"));

    try req.end(alloc);

    std.log.info("request:\n{s}", .{req.contents[0..req.contents_len]});

    var response_buff: []u8 = try alloc.alloc(u8, std.heap.pageSize() * 4);
    _ = sock.sock_write(fd, req.contents[0..req.contents_len]);

    std.log.info("response:", .{});
    var response_buff_offset: usize = 0;
    while (true) {
        const bytes_read = sock.sock_read(fd, response_buff);
        if (bytes_read == 0) {
            break;
        }
        const bytes_read_u: usize = @bitCast(bytes_read);
        if ((response_buff_offset + bytes_read_u) >= response_buff.len) {
            response_buff = try alloc.realloc(response_buff, @max(response_buff.len * 2, (response_buff_offset + bytes_read_u)));
            response_buff_offset += bytes_read_u;
            continue;
        }

        std.log.info("{s}", .{response_buff[response_buff_offset..(response_buff_offset + bytes_read_u)]});
        response_buff_offset += bytes_read_u;
    }
}

test "Main test" {
    var PORT: u16 = 4003;
    var IP = [4]u8{ 104, 21, 59, 19 };
    util.host_to_net(@ptrCast(@alignCast(&PORT)));
    util.host_to_net(IP[0..]);
}
