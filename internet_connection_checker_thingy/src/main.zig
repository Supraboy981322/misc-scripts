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

    var config:@import("config.zig").Config = undefined;
    {
        const home_dir = try std.process.getEnvVarOwned(alloc, "HOME");
        defer alloc.free(home_dir);
        const path = try std.fs.path.join(alloc, &[_][]const u8{
            home_dir,
            ".config",
            "Supraboy981322",
            "internet_connection_checker_thingy",
            "config"
        });
        defer alloc.free(path);
        var file = std.fs.openFileAbsolute(path, .{}) catch |e| {
            try stderr.print("{s}: {s}\n", .{
                switch (e) {
                    error.FileNotFound => "couldn't find config file",
                    else => @errorName(e),
                },
                path
            });
            std.process.exit(1);
        };
        defer file.close();
        var reader = &@constCast(&file.reader(&.{})).interface;
        const conf_src = try reader.allocRemaining(alloc, .unlimited); 
        config = try @import("config.zig").read(alloc, conf_src);
    }

    try stdout.print("using the domain: {s}\n", .{config.@"test domain"});

    var last_success:bool = false;
    var first:bool = true;

    loop: while (true) {
        defer {
            if (first) first = false;
            std.Thread.sleep(std.time.ns_per_s * config.@"test interval");
        }

        try stdout.print("checking...  ", .{});
        _ = std.net.getAddressList(alloc, config.@"test domain", 80) catch |e| switch (e) {
            error.NameServerFailure, error.UnknownHostName => {
                defer last_success = false;

                try stderr.print("failed\n", .{});
                if (last_success or first)
                    try hlp.notify("failed to resolve DNS");

                continue :loop;
            },
            else => @panic(@errorName(e)),
        };
        defer last_success = true;

        try stdout.print("success\n", .{});
        if (!last_success)
            try hlp.notify("DNS was able to be resolved");
    }
}
