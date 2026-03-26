const std = @import("std");

pub fn notify(comptime msg:[]const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer {
        _ = arena.reset(.free_all);
        _ = arena.deinit();
    }
    _ = try std.process.Child.run(.{
        .allocator = arena.allocator(),
        .argv = &[_][]const u8{ "notify-send", msg },
    }); 
}
