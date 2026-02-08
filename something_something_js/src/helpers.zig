const std = @import("std");
const globs = @import("globals.zig");

pub fn panic_err(e:anyerror) void {
    @panic(@errorName(e));
}
