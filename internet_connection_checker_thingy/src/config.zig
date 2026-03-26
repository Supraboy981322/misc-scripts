const std = @import("std");

const stderr = @import("globals.zig").stderr;

const Config = struct {
    @"test domain":[]const u8
};

pub fn read(returning_allocator:std.mem.Allocator, src:[]const u8) !Config {
    var arena = std.heap.ArenaAllocator.init(returning_allocator);
    defer {
        _ = arena.reset(.free_all);
        _ = arena.deinit();
    }
    const alloc = arena.allocator();

    var mem = try std.ArrayList(u8).initCapacity(alloc, 0);
    defer mem.deinit(alloc);

    var config:Config = .{
        .@"test domain" = "google.com",
    };

    var setting:enum { @"test domain", invalid } = .invalid;

    var line_no:usize = 1;
    for (src) |c| switch (c) {
        '=' => {
            if (mem.items.len < 1) {
                try stderr.print(
                    "invalid config token: '{c}' (missing key on line {d})\n",
                    .{c, line_no}
                );
                std.process.exit(1);
            }

            const trimmed = std.mem.trim(u8, mem.items, &std.ascii.whitespace);

            const thing = std.meta.stringToEnum(@TypeOf(setting), trimmed) orelse .invalid;

            switch (thing) {
                .invalid => {
                    try stderr.print(
                        "invalid config option: |{s}| (line {d})\n",
                        .{trimmed, line_no}
                    );
                    std.process.exit(1);
                },
                else => setting = thing,
            }
            mem.clearAndFree(alloc);
        },
        '\n' => {
            line_no += 1;
            if (setting != .invalid) {
                if (mem.items.len < 1) {
                    try stderr.print(
                        "invalid config value (newline) for option '{s}' "
                            ++ "(missing value on line {d})\n",
                        .{@tagName(setting), line_no}
                    );
                    std.process.exit(1);
                }

                const trimmed = std.mem.trim(u8, mem.items, &std.ascii.whitespace);

                switch (setting) {
                    .@"test domain" => {
                        config.@"test domain" = try returning_allocator.dupe(u8, trimmed);
                    },
                    .invalid => {
                        try stderr.print(
                            "invalid config option: |{s}| (line {d})\n",
                            .{@tagName(setting), line_no}
                        );
                        std.process.exit(1);
                    },
                }
                mem.clearAndFree(alloc);
            } else {
            }
        },
        else => try mem.append(alloc, c),
    };
    return config;
}
