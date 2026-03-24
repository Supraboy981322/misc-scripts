const std = @import("std");

//create stderr and stdout interfaces with no buffer (so I don't have to call 'flush()')
const stdout = &@constCast(&std.fs.File.stdout().writer(&.{})).interface;
const discard = &@constCast(&std.Io.Writer.Discarding.init(&.{})).writer;

pub fn main() !void {
    //the main allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var arena = std.heap.ArenaAllocator.init(allocator);
    var alloc = arena.allocator();
    defer {
        _ = arena.reset(.free_all);
        _ = arena.deinit();
    }

    var last_largest:usize = 0;
    loop: while (true) {
        const foo = alloc.alloc(u8, 1024) catch break :loop;
        try discard.print("{s}\n", .{foo});
        const cap = arena.queryCapacity();
        if (last_largest < cap) {
            try stdout.print("capacity: {d}\n", .{cap});
            last_largest = cap;
        }
    }
}
