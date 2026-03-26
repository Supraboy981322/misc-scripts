const std = @import("std");
const hlp = @import("helpers.zig");
const globs = @import("globals.zig");

const stdout = globs.stdout;
const stderr = globs.stderr;

const addr = "google.com";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var last_success:bool = false;
    var first:bool = true;

    loop: while (true) {
        defer {
            if (first) first = false;
            std.Thread.sleep(std.time.ns_per_s);
        }

        try stdout.print("checking...  ", .{});
        _ = std.net.getAddressList(alloc, addr, 80) catch |e| switch (e) {
            error.NameServerFailure, error.UnknownHostName => {
                if (last_success or first)
                    try hlp.notify("failed to resolve DNS");
                try stderr.print("failed\n", .{});
                last_success = false;
                continue :loop;
            },
            else => @panic(@errorName(e)),
        };

        try stdout.print("success\n", .{});
        if (!last_success)
            try hlp.notify("DNS was able to be resolved");

        last_success = true;
    }
}
