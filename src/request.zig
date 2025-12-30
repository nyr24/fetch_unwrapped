const std = @import("std");
const http = @import("http.zig");
const sock = @import("sock.zig");

// Example:
// GET /posts HTTP/2
// Host: jsonplaceholder.typicode.com
// User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0
// Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
// Accept-Language: en-US,en;q=0.5
// Accept-Encoding: gzip, deflate, br, zstd
// Upgrade-Insecure-Requests: 1
// Connection: keep-alive
// Cookie: _ga_E3C3GCQVBN=GS2.1.s1766792303$o4$g0$t1766792303$j60$l0$h0; _ga=GA1.1.673921261.1766707379
// Sec-Fetch-Dest: document
// Sec-Fetch-Mode: navigate
// Sec-Fetch-Site: none
// Sec-Fetch-User: ?1
// If-None-Match: W/"6b80-Ybsq/K6GwwqrYkAsFxqDXGC7DoM"
// Priority: u=0, i

pub const Request = struct {
    url: http.Url,
    method: http.Method,
    contents: []u8 = undefined,
    contents_len: u32 = 0,
    body: ?[*]u8,

    const Self = @This();

    pub fn init(
        alloc: std.mem.Allocator,
        protocol: http.Protocol,
        method: http.Method,
        domain: []const u8,
        path: []const u8,
        body: ?[*]u8,
    ) !Request {
        var req = Request{
            .url = .{
                .protocol = protocol,
                .domain = domain,
                .path = path,
            },
            .method = method,
            .body = body,
        };

        const BUF_LEN = 4096;
        req.contents = try alloc.alloc(u8, BUF_LEN);

        try req.construct(alloc);

        return req;
    }

    pub fn set_headers(self: *Self, alloc: std.mem.Allocator, headers: []http.Header) !void {
        for (headers) |header| {
            try self.set_header(alloc, header);
        }
    }

    pub fn set_header(self: *Self, alloc: std.mem.Allocator, header: http.Header) !void {
        try self.write_bytes(alloc, "{s}: {s}\r\n", .{ header.key.slice_full_as_const(), header.val.slice_full_as_const() });
    }

    pub fn set_cookies(self: *Self, alloc: std.mem.Allocator, cookies: []http.Cookie) !void {
        try self.write_bytes(alloc, "Cookie: ", .{});
        for (cookies, 0..cookies.len) |cookie, i| {
            try self.write_bytes(alloc, "{s}={s}", .{ cookie.key.slice_full_as_const(), cookie.val.slice_full_as_const() });
            if (i < cookies.len - 1) {
                try self.write_bytes(alloc, "; ", .{});
            }
        }
        try self.write_bytes(alloc, "\r\n", .{});
    }

    pub fn end(self: *Self, alloc: std.mem.Allocator) !void {
        try self.write_bytes(alloc, "\r\n", .{});
    }

    fn construct(self: *Self, alloc: std.mem.Allocator) !void {
        // Method + path + protocol
        try self.write_bytes(alloc, "{s} {s} {s}\r\n", .{ self.method.to_str(), self.url.path, self.url.protocol.to_str() });
        // Host
        try self.write_bytes(alloc, "Host: {s}\r\n", .{self.url.domain});
        // User-agent
        try self.write_bytes(alloc, "User-Agent: C-HTTP-Client/1.0\r\n", .{});
    }

    fn write_bytes(self: *Self, alloc: std.mem.Allocator, comptime fmt: []const u8, args: anytype) !void {
        if (std.fmt.bufPrint(self.contents[self.contents_len..], fmt, args)) |res| {
            self.contents_len += @intCast(res.len);
        } else |err| {
            std.debug.print("Write bytes err: {}", .{err});
            self.contents = try alloc.realloc(self.contents, self.contents_len * 2);
        }
    }

    pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
        alloc.free(self.contents);
        self.contents_len = 0;
    }
};
