const std = @import("std");
const hlp = @import("helpers.zig");
const parser = @import("parser.zig");

const stdout = &@constCast(&std.fs.File.stdout().writer(&.{})).interface;
const stderr = &@constCast(&std.fs.File.stderr().writer(&.{})).interface;

const FormatSpecifiers = enum {
    @"s",
    @"d",
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = b: {
        const raw = try std.process.argsAlloc(alloc);
        defer std.process.argsFree(alloc, raw);

        var res = try std.ArrayList([]u8).initCapacity(alloc, 0);
        defer _ = res.deinit(alloc);

        for (raw) |a| try res.append(
            alloc, try parser.parse_literal(alloc, a)
        );

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

    var res = try std.ArrayList(u8).initCapacity(alloc, 0);
    defer _ = res.deinit(alloc);
    var i:u3 = 0;
    const mem_len = comptime std.math.maxInt(@TypeOf(i));
    var mem:[mem_len]u8 = undefined;
    var a_no:usize = 2;
    for (args[1]) |b| {
        if (b == '{') {
            i = if (i > 0) 0 else 1;
        } else if (i > 0) if (b != '}') { 
            mem[@intCast(i-1)] = b;
            if (@as(usize, @intCast(i)) + 1 > mem_len) {
                stderr.print(
                    \\invalid format string
                    \\  unknown format specifier: {s}
                    ++ "\n", .{mem[0..i]}
                ) catch {};
                std.process.exit(1);
            }
            i += 1;
        } else {
            defer i = 0;
            i -= 1;
            if (args[1..].len < a_no) {
                stderr.print(
                    \\too many format specifiers
                    \\  not enough args to populate all given specifiers
                    ++ "\n", .{}
                ) catch {};
                std.process.exit(1);
            }
            const specifier = std.meta.stringToEnum(
                FormatSpecifiers, mem[0..i]
            ) orelse {
                stderr.print(
                    \\invalid format string
                    \\  unknown format specifier: {s}
                    ++ "\n", .{mem[0..i]}
                ) catch {};
                std.process.exit(1);
                unreachable;
            };
            switch (specifier) {
                .@"s" => try res.appendSlice(alloc, args[a_no]),
                .@"d" => {
                    if (hlp.str_is_num(args[a_no]))
                        try res.appendSlice(alloc, args[a_no])
                    else {
                        stderr.print(
                            \\invalid format string
                            \\  specified number, but provided arg isn't a number: {s}
                            ++ "\n", .{args[a_no]}
                        ) catch {};
                        std.process.exit(1);
                    }
                },
            }
            a_no += 1;
        } else
            try res.append(alloc, b);
    }

    stdout.print("{s}", .{res.items}) catch {};
}
