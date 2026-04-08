const std = @import("std");
const hlp = @import("helpers.zig");

const stdout = &@constCast(&std.fs.File.stdout().writer(&.{})).interface;
const stderr = &@constCast(&std.fs.File.stderr().writer(&.{})).interface;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer {
        _ = arena.deinit();
    }
    const alloc = gpa.allocator();
    const args = b: {
        const raw = try std.process.argsAlloc(alloc);
        defer std.process.argsFree(alloc, raw);
        var res = try std.ArrayList([]u8).initCapacity(alloc, 0);
        defer _ = res.deinit(alloc);
        for (raw) |a| try res.append(alloc, try hlp.parse_literal(alloc, a));
        break :b try res.toOwnedSlice(alloc);
    };

    defer {
        for(args) |a| alloc.free(a);
        alloc.free(args);
    }

    if (args.len < 2) {
        stderr.print("not enough args, need something to print\n", .{}) catch {};
        std.process.exit(1);
    }

    stdout.print("{s}", .{args[1]}) catch {};
}
