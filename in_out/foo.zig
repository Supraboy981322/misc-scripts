const std = @import("std");

const Setup = struct {
    colorize:?packed struct(u24){
        r:u8,
        g:u8,
        b:u8,
    } = null,
};

pub fn main(init:std.process.Init) !u8 {
    var stderr = std.Io.File.stderr().writer(init.io, &.{});
    const stuff = do_args(init) catch |e| {
        try stderr.interface.print("{t}\n", .{e});
        try stderr.flush();
        return 1;
    };

    var stdout_buf:[1]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(init.io, &stdout_buf);

    var stdin_buf:[1]u8 = undefined;
    var stdin = std.Io.File.stdin().reader(init.io, &stdin_buf);

    if (stuff.colorize) |color| while (true) {
        try stdout.interface.print("\x1b[38;2;{d};{d};{d}m", .{color.r, color.g, color.b});
        _ = try stdin.interface.stream(&stdout.interface, .limited(1));
        try stdout.interface.writeAll("\x1b[0m");
    } else {} else
        while (true)
            _ = try stdin.interface.stream(&stdout.interface, .unlimited);

    return 0;
}

fn do_args(init:std.process.Init) !Setup {
    var itr = try init.minimal.args.iterateAllocator(init.arena.allocator());
    defer _ = init.arena.deinit();
    _ = itr.skip();

    var res:Setup = .{};
    while (itr.next()) |arg| {
        const opt:[]const u8, const v:?[]const u8 =
            if (std.mem.cutScalar(u8, arg, '=')) |parts| parts else .{ arg, null };
        const match = std.meta.stringToEnum(
            std.meta.FieldEnum(Setup), opt
        ) orelse
            return error.InvalidArg;

        switch (match) {
            .colorize => {
                if (v == null) return error.IncompleteArg;
                var red:?u8, var green:?u8, var blue:?u8 = .{ null, null, null };
                var start:u4 = 0;
                for (v.?, 0..) |b, i| if (b == ',' or i == v.?.len-1) {
                    if (blue) |_| return error.InvalidOptionValue;
                    const which:*?u8 =
                        if (red) |_|
                            if (green) |_|
                                &blue
                            else
                                &green
                        else
                            &red;

                    if (start+1 < i) {
                     const str = v.?[start .. if (i == v.?.len-1) i+1 else i];
                        which.* = std.fmt.parseInt(u8, str, 10) catch {
                            return error.InvalidOptionValue;
                        };
                    } else
                        which.* = 0;
                    start = @intCast(i+1);
                };
                res.colorize = .{
                    .r = red orelse return error.InvalidOptionValue,
                    .g = green orelse return error.InvalidOptionValue,
                    .b = blue orelse return error.InvalidOptionValue,
                };
            },
        }
    }

    return res;
}
