const std = @import("std");
pub const fns = @import("js_funcs.zig");
const globs = @import("globals.zig");
pub const mu = @cImport({
    @cInclude("mujs.h");
});

pub const func = struct {
    name:[]const u8,
    func:*const fn (?*mu.js_State) callconv(.c) void,
};

pub const run = struct {
    pub fn c_str(s:State, code:[*c]u8) u8 {
        const ret = mu.js_dostring(s.mujs, code);
        return @intCast(ret);
    }
};

pub const IO = struct {
    stdout:*std.Io.Writer,
    stderr:*std.Io.Writer,
    stdin:*std.Io.Reader,
};

pub const State = struct {
    mujs:?*mu.js_State,
    io:IO,
    pub fn new(
        io:?IO,
        comptime N:usize,
        comptime funcs:?*const [N]func,
    ) !State {
        const Io:IO = if (io) |i| i else blk: {
            break :blk .{
                .stdout = globs.stdout,
                .stderr = globs.stderr,
                .stdin = b: {
                    var buf:[1024]u8 = undefined;
                    var re = std.fs.File.stdin().reader(&buf);
                    break :b &re.interface;
                }
            };
        };

        const s = mu.js_newstate(null, null, mu.JS_STRICT).?;
        const fs = if (funcs) |fs| fs else @constCast(&[_]funcs{});
        const alloc = std.heap.page_allocator;

        for (fs) |f| {
            const fn_C_name = try alloc.dupeZ(u8, f.name);
            defer alloc.free(fn_C_name);
            mu.js_newcfunction(s, f.func, fn_C_name, 1);
            mu.js_setglobal(s, fn_C_name);
        }

        return .{
            .mujs = s,
            .io = Io,
        };
    }
};
