const std = @import("std");

pub fn main(init:std.process.Init) !u8 {
    var stdout = std.Io.File.stdout().writer(init.io, &.{});
    var stdin = std.Io.File.stdin().reader(init.io, &.{});
    while (true) {
        _ = try stdin.interface.stream(&stdout.interface, .unlimited);
    }

    return 0;
}
