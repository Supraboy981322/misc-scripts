const std = @import("std");

const stdout = &@constCast(&std.fs.File.stdout().writer(&.{})).interface;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

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
        for (args[0..args.len - 1]) |a|
            alloc.free(a);

    var upnext = try pick_item(alloc);
    while (true) {
        alloc.free(args[7]);
        args[7] = try alloc.dupe(u8, upnext);
        alloc.free(upnext);
        upnext = try pick_item(alloc);
        try stdout.print(
            "\x1b[3A\x1b[2K\r\x1b[33mplaying: "
                ++ "\x1b[34m{s}\x1b[0m\n\x1b[2K\t\x1b[35mupnext: "
                    ++ "\x1b[36m{s}\x1b[0m\n\x1b[2K",
            .{ args[7], upnext }
        );
        var child = std.process.Child.init(&args, alloc);
        _ = try child.spawnAndWait();
    }
}

pub fn pick_item(alloc:std.mem.Allocator) ![]const u8 {
    var dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
    var walker = try dir.walk(alloc);
    defer walker.deinit();
    var arr = try std.ArrayList([]const u8).initCapacity(alloc, 0);
    defer {
        for (arr.items) |file|
            alloc.free(file);
        arr.deinit(alloc);
    }
    while (try walker.next()) |entry| if (entry.kind == .file) {
        try arr.append(alloc, try alloc.dupe(u8, entry.basename));
    };
    const idx = std.crypto.random.uintAtMost(usize, arr.items.len - 1);
    const picked = arr.items[idx];
    return alloc.dupe(u8, picked);
}
