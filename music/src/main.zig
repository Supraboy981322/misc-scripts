const std = @import("std");

pub fn main(init:std.process.Init) !void {
    const alloc = init.gpa;

    var stdout_buf:[1024]u8 = undefined;
    var stdout_wr = std.Io.File.stdout().writer(init.io, &stdout_buf);
    const stdout = &stdout_wr.interface;

    var args = [8][]const u8 {
        "ffplay",
        "-nodisp",
        "-autoexit",
        "-hide_banner",
        "-loglevel",
        "quiet",
        "-stats",
        ""
    };

    for (args, 0..) |arg, i|
        args[i] = try alloc.dupe(u8, arg);
    defer
        for (args) |a|
            alloc.free(a);

    var upnext = try pick_item(init.io, alloc);
    defer alloc.free(upnext);
    try stdout.print("\n\n\n", .{});
    try stdout.flush();
    while (true) {
        alloc.free(args[7]);
        args[7] = try alloc.dupe(u8, upnext);
        alloc.free(upnext);
        upnext = try pick_item(init.io, alloc);
        try stdout.print(
            "\x1b[3A\x1b[2K\r\x1b[33mplaying: "
                ++ "\x1b[34m{s}\x1b[0m\n\x1b[2K\t\x1b[35mupnext: "
                    ++ "\x1b[36m{s}\x1b[0m\n\x1b[2K",
            .{ args[7], upnext }
        );
        try stdout.flush();
        var child = try std.process.spawn(init.io, .{
            .argv = &args,
            .stdout = .pipe,
            .stderr = .pipe,
            .stdin = .pipe,
        });
        _ = try child.wait(init.io);
    }
}

pub fn pick_item(io:std.Io, alloc:std.mem.Allocator) ![]const u8 {
    var dir = try std.Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });
    var walker = try dir.walk(alloc);
    defer walker.deinit();
    var arr = try std.ArrayList([]const u8).initCapacity(alloc, 0);
    defer {
        for (arr.items) |file|
            alloc.free(file);
        arr.deinit(alloc);
    }
    while (try walker.next(io)) |entry| if (entry.kind == .file) {
        try arr.append(alloc, try alloc.dupe(u8, entry.basename));
    };
    const random = (std.Random.IoSource{ .io = io }).interface();
    const idx = random.uintAtMost(usize, arr.items.len - 1);
    const picked = arr.items[idx];
    return alloc.dupe(u8, picked);
}
