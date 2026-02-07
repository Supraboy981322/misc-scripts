const std = @import("std");
const js = @import("js.zig");

const mu = js.mu;

var stdout_buf:[1024]u8 = undefined;
var stdout_wr = std.fs.File.stdout().writer(&stdout_buf);
const stdout = &stdout_wr.interface;

pub fn print(J:?*mu.js_State) callconv(.c) void {
    const str = mu.js_tostring(J, 1);
    stdout.print("{s}\n", .{str}) catch {};
    stdout.flush() catch {};
    mu.js_pushundefined(J);
}
