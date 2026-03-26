const std = @import("std");

pub fn notify(comptime msg:[]const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer {
        _ = arena.reset(.free_all);
        _ = arena.deinit();
    }

    _ = std.process.Child.run(.{
        .allocator = arena.allocator(),
        .argv = &[_][]const u8{ "notify-send", msg },
    }) catch |e| {
        try @import("globals.zig").stderr.print(
            "failed to send notification: {t} (is 'notify-send' in your $PATH?)\n",
            .{e}
        );
        std.process.exit(1);
    };
}
