const std = @import("std");

var opts:[*:null]const ?[*:0]const u8 = &[_:null]?[*:0]const u8 {
    "-nodisp",
    "-autoexit",
    "-hide_banner",
    "-loglevel", "quiet",
    "-stats",
    "",
    null,
};


pub fn main() !void {
    const opts_len = std.mem.span(opts).len;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    opts[opts_len - 2] = pick_item(alloc);
    for (std.mem.span(opts)) |opt| if (opt) |o|
        std.debug.print("{s}\n", .{o});
}

pub fn pick_item(alloc:std.mem.Allocator) [*:0]const u8 {
    var walker = try std.fs.cwd().walk(alloc);
    defer walker.deinit(alloc);
    var arr = try std.ArrayList([:0]const u8);
    defer {
        for (arr) |file|
            alloc.free(file);
        arr.deinit(alloc);
    }
    for (walker.next()) |entry| if (entry.kind == .file) {
        try arr.append(alloc, try alloc.dupe(u8, entry.basename));
    };
    const idx = std.crypto.random.uintAtMost(usize, arr.items.len - 1);
    const picked = arr.items[idx];
    return picked.ptr;
}
