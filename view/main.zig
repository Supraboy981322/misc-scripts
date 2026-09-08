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
                    var perm_buf:["drwxr-xr-x".len]u8 = @splat('-');
                    var i:usize = 0;
                    perm_buf[i] = switch (entry_stat.kind) {
                        .file => '-',
                        .directory => 'd',
                        .sym_link => 'l',
                        .named_pipe => 'p',
                        .character_device => 'c',
                        .block_device => 'b',
                        .unix_domain_socket => 's',
                        else => '?',
                    };
                    i += 1;
                    const S = std.posix.S;
                    const m = entry_stat.permissions.toMode();
                    perm_buf[i..][0..3].* = .{
                        if (m & S.IRUSR != 0) 'r' else '-',
                        if (m & S.IWUSR != 0) 'w' else '-',
                        if (m & S.ISUID != 0)
                            if (m & S.IXUSR != 0) 's' else 'S'
                        else
                            if (m & S.IXUSR != 0) 'x' else '-',
                    };
                    i += 3;
                    perm_buf[i..][0..3].* = .{
                        if (m & S.IRGRP != 0) 'r' else '-',
                        if (m & S.IWGRP != 0) 'w' else '-',
                        if (m & S.ISGID != 0)
                            if (m & S.IXGRP != 0) 's' else 'S'
                        else
                            if (m & S.IXGRP != 0) 'x' else '-',
                    };
                    i += 3;
                    perm_buf[i..][0..3].* = .{
                        if (m & S.IROTH != 0) 'r' else '-',
                        if (m & S.IWOTH != 0) 'w' else '-',
                        if (m & S.ISVTX != 0)
                            if (m & S.IXOTH != 0) 't' else 'T'
                        else
                            if (m & S.IXOTH != 0) 'x' else '-',
                    };
                    i += 3;
                    try stdout.interface.print("{s} {s}\n", .{perm_buf, entry.basename});
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
            else => std.debug.panic("don't know what to do with: {t}", .{path_stat.kind}),
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
