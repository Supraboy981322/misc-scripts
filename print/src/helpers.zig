const std = @import("std");
const parser = @import("parser.zig");

pub fn is_alpha(b:u8) bool {
    return for ([_]bool{
        b >= 'a' and b <= 'z',
        b >= 'A' and b <= 'Z',
    }) |check| {
        if (check) break true;
    } else false;
}

pub fn is_num(b:u8) bool {
    return b >= '0' and b <= '9';
}

pub fn str_is_num(raw:[]u8) bool {
    const alloc = std.heap.page_allocator; //why're people scared of page allocation?
    const str = parser.parse_literal(alloc, raw) catch return false;
    defer alloc.free(str);
    return for (str) |b| {
        if (b > '9' or b < '0') break false;
    } else true;
}
