const std = @import("std");

var paths:std.ArrayList([]const u8) = .empty;

pub fn main(init:std.process.Init) !u8 {
    defer paths.deinit(init.gpa);
    try doArgs(init);
    var out_buf:[1024]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(init.io, &out_buf);
    var in_buf:[1024]u8 = undefined;
    while (paths.pop()) |raw_path| {
        var path = raw_path;
        _ = &path;
        const stat = try std.Io.Dir.cwd().statFile(init.io, path, .{});
        switch (stat.kind) {
            .directory => {
                var dir = try std.Io.Dir.cwd().openDir(init.io, path, .{ .iterate = true });
                var itr = try dir.walkSelectively(init.gpa);
                defer itr.deinit();
                while (try itr.next(init.io)) |entry| {
                    try stdout.interface.print("{s}\n", .{entry.basename});
                }
                try stdout.interface.flush();
            },
            .character_device, .file => {
                var file = try std.Io.Dir.cwd().openFile(init.io, path, .{});
                defer file.close(init.io);
                var reader = file.reader(init.io, &in_buf);
                _ = try reader.interface.streamRemaining(&stdout.interface);
                try stdout.interface.flush();
            },
            else => std.debug.panic("don't know what to do with: {t}", .{stat.kind}),
        }
    }
    return 0;
}

pub fn doArgs(init:std.process.Init) !void {
    var args = init.minimal.args.iterate();
    _ = args.skip();
    while (args.next()) |arg| {
        try paths.append(init.gpa, arg);
    }
    if (paths.items.len == 0)
        try paths.append(init.gpa, "/dev/stdin");
}
