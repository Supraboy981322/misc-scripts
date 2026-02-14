//not really a fork bomb,
//  but Zig currently has no async,
//    so this'll do for now

const std = @import("std");

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    var arr = try std.ArrayList(usize).initCapacity(alloc, 0);
    defer _ = arr.deinit(alloc);
    for (0..std.math.maxInt(usize)) |i| {
        try arr.append(alloc, std.math.maxInt(usize));
        std.debug.print("{d} of {d}\n", .{i, std.math.maxInt(usize)});
    }

    std.debug.print("{any}\n", .{arr.items});
}
