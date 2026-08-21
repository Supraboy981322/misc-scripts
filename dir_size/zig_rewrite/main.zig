const std = @import("std");

var stuff:std.process.Init = undefined;
var counter:std.atomic.Value(usize) = .init(0);

pub fn main(init:std.process.Init) !u8 {
    stuff = init;
    const cwd = try std.Io.Dir.cwd().openDir(stuff.io, ".", .{ .iterate = true });
    try recurse(cwd);
    std.log.info("total: {d}", .{counter.load(.seq_cst)});
    return 0;
}

pub fn recurseShim(dir:std.Io.Dir) std.Io.Cancelable!void {
    recurse(dir) catch |err| {
        std.log.err("{t}", .{err});
        return error.Canceled;
    };
}

pub fn recurse(dir:std.Io.Dir) !void {
    defer dir.close(stuff.io);
    var wg:std.Io.Group = .init;
    defer wg.cancel(stuff.io);
    var itr = dir.iterate();
    while (try itr.next(stuff.io)) |entry| switch (entry.kind) {
        .file => {
            var file = try dir.openFile(stuff.io, entry.name, .{});
            defer file.close(stuff.io);
            _ = counter.fetchAdd(try file.length(stuff.io), .seq_cst);
        },
        .directory => {
            const d = try dir.openDir(stuff.io, entry.name, .{ .iterate = true });
            wg.async(stuff.io, recurseShim, .{d});
        },
        else => |tag| {
            std.log.debug("skipping ({t}): {s}", .{tag, entry.name});
        },
    };
    try wg.await(stuff.io);
}
