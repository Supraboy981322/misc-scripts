const std = @import("std");
const globs = @import("globals.zig");

const stdout = globs.stdout;
const stderr = globs.stderr;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    const addr = "google.com";
    var list = std.net.getAddressList(alloc, addr, 80) catch |e| switch (e) {
        error.NameServerFailure, error.UnknownHostName => {
            try stderr.print("failed to get addr\n", .{});
            std.process.exit(1);
        },
        else => @panic(@errorName(e)),
    };
    defer list.deinit();
    for (list.addrs) |a| {
        try a.format(stdout);
        _ = try stdout.write("\n"); 
   }
}
