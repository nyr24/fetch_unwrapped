const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const sock = @import("sock.zig");
const linux = std.os.linux;
const FixedArray = @import("fixed_array.zig").FixedArray;

pub const Header = struct {
    key: FixedArray(u8, 64) = undefined,
    val: FixedArray(u8, 128) = undefined,

    pub fn init(key: []const u8, val: []const u8) Header {
        return .{
            .key = .init_from_slice(key),
            .val = .init_from_slice(val),
        };
    }
};

pub const Cookie = struct {
    key: FixedArray(u8, 64) = undefined,
    val: FixedArray(u8, 128) = undefined,

    pub fn init(key: []const u8, val: []const u8) Cookie {
        return .{
            .key = .init_from_slice(key),
            .val = .init_from_slice(val),
        };
    }
};

pub const Port = enum(u16) {
    HTTP = 80,
    HTTPS = 443,
};

pub const Protocol = enum {
    HTTP10,
    HTTP11,
    HTTP2,

    pub fn to_str(self: Protocol) []const u8 {
        switch (self) {
            .HTTP10 => return "HTTP/1.0",
            .HTTP11 => return "HTTP/1.1",
            .HTTP2 => return "HTTP/2",
        }
    }
};

pub const Url = struct {
    protocol: Protocol,
    domain: []const u8,
    path: []const u8,
};

pub const Method = enum {
    GET,
    POST,
    PATCH,
    DELETE,
    OPTIONS,

    pub fn to_str(self: Method) []const u8 {
        switch (self) {
            .GET => return "GET",
            .POST => return "POST",
            .PATCH => return "PATCH",
            .DELETE => return "DELETE",
            .OPTIONS => return "OPTIONS",
        }
    }

    pub fn from_str(s: []const u8) Method {
        if (mem.eql(u8, s, "GET")) {
            return .GET;
        } else if (mem.eql(u8, s, "POST")) {
            return .POST;
        } else if (mem.eql(u8, s, "PATCH")) {
            return .PATCH;
        } else if (mem.eql(u8, s, "DELETE")) {
            return .DELETE;
        } else {
            return .OPTIONS;
        }
    }
};
