const std = @import("std");

var paths:std.ArrayList([]const u8) = .empty;

pub fn main(init:std.process.Init) !u8 {
    defer paths.deinit(init.gpa);
    try doArgs(init);
    var out_buf:[1024]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(init.io, &out_buf);
    var in_buf:[1024]u8 = undefined;
    while (paths.pop()) |raw_path| {
        var path = raw_path;
        _ = &path;
        const path_stat = try std.Io.Dir.cwd().statFile(init.io, path, .{});
        switch (path_stat.kind) {

            .directory => {
                var dir = try std.Io.Dir.cwd().openDir(init.io, path, .{ .iterate = true });
                var itr = try dir.walkSelectively(init.gpa);
                defer itr.deinit();
                while (try itr.next(init.io)) |entry| {

                    const entry_stat = try dir.statFile(init.io, entry.basename, .{});
                    const m = entry_stat.permissions.toMode();
                    const S = std.posix.S;
                    var i:@Vector(3, usize) = .{ 2, 5, 7 };
                    const style = 0;
                    const color = 1;
                    const char  = 2;
                    const template = "\x1b[0;30m-";

                    var buf = stdout.interface.buffer[0..template.len * 10];
                    stdout.interface.end = buf.len;
                    @memcpy(buf, template ** 10);
                    buf[i[style]] = '1';
                    if (entry.kind != .file) {
                        buf[i[color]] = '4';
                        buf[i[char]] = switch(entry.kind) {
                            .directory => 'd',
                            .sym_link => 'l',
                            .named_pipe => 'p',
                            .character_device => 'c',
                            .block_device => 'b',
                            .unix_domain_socket => 's',
                            else => '?',
                        };
                    } else {
                        buf[i[color]-1] = '9';
                    }

                    const table = [_]struct{ s:u4, o:struct{ s:@TypeOf(m), b:u8 } }{
                        .{ .s = 0, .o = .{ .s = S.ISUID, .b = 's' } },
                        .{ .s = 3, .o = .{ .s = S.ISGID, .b = 's' } },
                        .{ .s = 6, .o = .{ .s = S.ISVTX, .b = 't' } },
                    };
                    for (table) |thing| inline for (0..3) |j| {
                        i += @splat(template.len);
                        const mask = @as(u9, 0b100_000_000) >> @intCast(thing.s + j);
                        const s = (m & mask) != 0;
                        if (j < 2) {
                            if (!s) {
                                buf[i[style]] = '1';
                                buf[i[color]-1] = '9';
                            } else {
                                buf[i[char]], buf[i[color]] = switch (j) {
                                    0 => .{ 'r', '3' },
                                    1 => .{ 'w', '1' },
                                    else => unreachable,
                                };
                            }
                            continue;
                        }
                        const o = (m & thing.o.s) != 0;
                        if (s != o or (s and o)) {
                            buf[i[char]] =
                                if (s)
                                    ([_]u8{'x', thing.o.b})[@intFromBool(o)]
                                else
                                    thing.o.b - 32;
                            buf[i[color]] = if (o) '5' else '2';
                        } else {
                            buf[i[style]] = '1';
                            buf[i[color]-1] = '9';
                        }
                    };

                    try stdout.interface.print("\x1b[0m \x1b[1;{s}m{s}\n", .{
                        if (entry_stat.kind == .directory) "34" else "0",
                        entry.basename,
                    });
                    try stdout.interface.flush();
                }
                try stdout.interface.flush();
            },

            .character_device, .file => {
                var file = try std.Io.Dir.cwd().openFile(init.io, path, .{});
                defer file.close(init.io);
                var reader = file.reader(init.io, &in_buf);
                _ = try reader.interface.streamRemaining(&stdout.interface);
                try stdout.interface.flush();
            },

            else => std.debug.panic(
                "don't know what to do with: {t} ({s})", .{path_stat.kind, path}
            ),
        }
    }
    return 0;
}

pub fn doArgs(init:std.process.Init) !void {
    var args = init.minimal.args.iterate();
    _ = args.skip();
    while (args.next()) |arg| {
        try paths.append(init.gpa, arg);
    }
    if (paths.items.len == 0)
        try paths.append(init.gpa, "/dev/stdin");
}
