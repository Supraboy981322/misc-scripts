const std = @import("std");
const js = @import("js.zig");
const globs = @import("globals.zig");

const mu = js.mu;

const stdout = globs.stdout;
const stderr = globs.stderr;

pub fn print(J:?*mu.js_State) callconv(.c) void {
    const str = mu.js_tostring(J, 1);
    stdout.print("{s}\n", .{str}) catch {};
    stdout.flush() catch {};
    mu.js_pushundefined(J);
}

pub const p = struct {
    pub fn out(J:?*mu.js_State) callconv(.c) void {
        const str = mu.js_tostring(J, -1);
        stdout.print("{s}", .{str}) catch {};
        stdout.flush() catch {};
        mu.js_pushundefined(J);
    }
    pub fn err(J:?*mu.js_State) callconv(.c) void {
        const str = mu.js_tostring(J, 1);
        stderr.print("{s}", .{str}) catch {};
        stderr.flush() catch {};
        mu.js_pushundefined(J);
    }
}; 
