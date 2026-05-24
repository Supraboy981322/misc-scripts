const std = @import("std");

const Setup = packed struct(u8) {
    colorize:bool = false,
    _two:u1 = 0,
    _three:u1 = 0,
    _four:u1 = 0,
    _five:u1 = 0,
    _six:u1 = 0,
    _seven:u1 = 0,
    _eight:u1 = 0,
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

    if (!stuff.colorize) while (true) {
        _ = try stdin.interface.stream(&stdout.interface, .unlimited);
    };

    while (true) {
        try stdout.interface.writeAll("\x1b[33m");
        _ = try stdin.interface.stream(&stdout.interface, .limited(1));
        try stdout.interface.writeAll("\x1b[0m");
    }

    return 0;
}

fn do_args(init:std.process.Init) !Setup {
    var itr = try init.minimal.args.iterateAllocator(init.arena.allocator());
    defer _ = init.arena.deinit();
    _ = itr.skip();

    var res:Setup = .{};
    while (itr.next()) |arg| {
        const match = std.meta.stringToEnum(
            std.meta.FieldEnum(Setup), arg
        ) orelse
            return error.InvalidArg;

        switch (match) {
            .colorize => res.colorize = true,
            else => return error.InvalidArg,
        }
    }
    return res;
}
