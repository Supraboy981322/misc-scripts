const std = @import("std");

var paths:std.ArrayList([]const u8) = .empty;
const opts = struct {
    pub var l = false;
    pub var a = false;
    pub var D = false;
};

pub fn main(init:std.process.Init) !u8 {
    defer paths.deinit(init.gpa);
    try doArgs(init);

    var out_buf:[1024]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(init.io, &out_buf);
    const term_width = blk: {
        var s:extern struct {
            ws_row:u16 = 0,
            ws_col:u16 = 0,
            ws_xpixel:u16 = 0,
            ws_ypixel:u16 = 0,
        } = .{};
        if (std.os.linux.ioctl(1, 0x5413, @intFromPtr(&s)) != 0) {
            std.log.debug("failed to query terminal size",.{});
            break :blk 80;
        }
        break :blk s.ws_col;
    };

    var in_buf:[1024]u8 = undefined;
    const many = paths.items.len > 1;

    while (paths.pop()) |raw_path| {
        var path = raw_path;
        _ = &path;
        if (many) {
            try stdout.interface.print("\n{s}:\n", .{path});
            try stdout.interface.flush();
        }
        errdefer std.log.info("at path |{s}|", .{path});
        const path_stat = try std.Io.Dir.cwd().statFile(init.io, path, .{});
        switch (path_stat.kind) {

            .directory => {
                var dir = try std.Io.Dir.cwd().openDir(init.io, path, .{ .iterate = true });
                var itr = try dir.walkSelectively(init.gpa);
                defer itr.deinit();
                var count:usize = 0;
                var longest:usize = 0;
                while (try itr.next(init.io)) |entry| : (count += 1)
                    longest = @max(entry.basename.len + 2, longest);
                itr.deinit();
                itr = try dir.walkSelectively(init.gpa);
                var col:usize = 0;
                var pos:usize = 0;
                while (try itr.next(init.io)) |entry| : (pos += 1) {
                    if (entry.basename.len > 0 and entry.basename[0] == '.' and !opts.a) continue;
                    errdefer {
                        stdout.interface.writeByte('\n') catch {};
                        stdout.interface.flush() catch {};
                        std.log.info("at entry |{s}|", .{entry.basename});
                    }
                    const entry_stat = try dir.statFile(init.io, entry.basename, .{
                        .follow_symlinks = false
                    });

                    if (opts.l) {
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
                            const o = if (j == 2) (m & thing.o.s) != 0 else false;
                            if (!(s != o or (s and o))) {
                                buf[i[style]] = '1';
                                buf[i[color]-1] = '9';
                            } else if (j < 2) {
                                buf[i[char]], buf[i[color]] = switch (j) {
                                    0 => .{ 'r', '3' },
                                    1 => .{ 'w', '1' },
                                    else => comptime unreachable,
                                };
                            } else {
                                buf[i[char]] =
                                    if (s)
                                        ([_]u8{'x', thing.o.b})[@intFromBool(o)]
                                    else
                                        thing.o.b - 32;
                                buf[i[color]] = if (o) '5' else '2';
                            }
                        };

                        try stdout.interface.writeAll("\x1b[0m ");
                    }

                    const ext = blk: {
                        const e = std.fs.path.extension(entry.basename);
                        break :blk e[@min(e.len-|1, 1)..e.len];
                    };
                    try stdout.interface.print("\x1b[{s}m{s}\x1b[0m", .{
                        switch (entry.kind) {
                            .directory => "1;34",
                            .sym_link => "1;36",
                            else => if (known_extensions.get(ext)) |c|
                                c.color
                            else if (ext.len > 0 and ext[ext.len-1] == '~')
                                known_extensions.get("~").?.color
                            else
                                "0"
                        },
                        entry.basename,
                    });
                    col += 1;
                    if (opts.l or col > ((term_width / longest)-|1) or pos == count-1) {
                        col = 0;
                        try stdout.interface.writeByte('\n');
                    } else if (pos < count-1) {
                        const len = longest - (entry.basename.len);
                        _ = try stdout.interface.splatByte(' ', len);
                    }
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
        try stdout.interface.flush();
    }
    return 0;
}

pub fn doArgs(init:std.process.Init) !void {
    var args = init.minimal.args.iterate();
    _ = args.skip();
    var ignore_rest = false;
    while (args.next()) |arg| {
        if (arg.len > 0 and !ignore_rest and arg[0] == '-') {
            if (arg.len == 1) {
                try paths.append(init.gpa, "/dev/stdin");
                continue;
            }
            for (arg[1..]) |a| switch (a) {
                'l' => opts.l = true,
                'a' => opts.a = true,
                'D' => opts.D = true,
                '-' => ignore_rest = true,
                else => return error.UnknownArgument,
            };
            continue;
        }
        try paths.insert(init.gpa, 0, arg);
    }
    if (paths.items.len == 0) {
        try paths.append(init.gpa, if (opts.D) "." else "/dev/stdin");
    }
}

pub const known_extensions = blk: {
    const V = struct { color:[]const u8 };
    var res:[]const struct{ []const u8, V } = &.{};
    for ([_]struct{ []const []const u8, V }{

        .{
            &.{
                "jpg", "jpeg",
                "png",
                "mp4", "mpeg4",
                "mp3", "mpeg3",
                "mpeg",
                "flac",
                "wav",
                "mov",
                "bmp",
                "gif",
                "xcf",
                "pdf",
            },
            .{ .color = "1;95" }
        },

        .{
            &.{
                "tar", "zip", "pak",
                "br", "xz", "lz", "lzma", "bz", "bz2", "lzo", "gz", "flate",
                "txz", "tgz", "tbr", "tlz", "tbz", "tbz2", "taz", "tzma",
                "7z", //do people really use this?
                "torrent",
            },
            .{ .color = "1;31" }
        },

        .{
            &.{
                "jai", //can't wait
                "h", //this' the best they could think of?
                "c", //so close to perfection
                "cpp", "c++", //far too complicated
                "ok", "oskar", //my ideal language (WIP (private project))
                "zig", "zon", //sad that this' as close as modern languages get to not being a pain in the ass
                "asm", //everyone should write something (semi) serious at least once in assembly
                "nix", //I don't understand why one would do it any other way
                "src", "script", //why name it anyways?
                "b",
                "el", "cl", "lisp", //neat
                "org", //nice
                "ml", //I return to this *[insert tomorrow's date]*
                "vim", "vimscript", //kind-of crappy
                "sh",
                "lua", //meh
                "go", //feels like toy
                "js", "py", //I cannot form words for these
                "ts", //why?
                "cc",
                "md", //ugh
                "xml", "json", "conf", "csv",
                "bat",
                "html", //ehh
                "bdf", //at least it can be read and parsed manually easily
                "odin", //you usually write TS, you're feeling adventurous, but you're scared of a proper low-level language
                "rs", //just no
                "java", //people really use this outside of school?
            },
            .{ .color = "1;33" },
        },

        .{
            &.{
                "elf",
                "bin",
                "out",
                "iso",
                "rom",
                "qcow2",
                "p8",
                "raw",
                "img",
                "nes",
                "wasm",
                "c64",
                "jar",
                "gba", "gb", "gbc",
                "wad",
                "gg",
                "nds",
                "cue",
                "d64",
                "fds",
                "3dsx",
                "cia",
                "pcx",
                "md2",
                "gen",
                "n64",
                "z64",
            },
            .{ .color = "0;93" },
        },

        .{
            &.{ "~", "old", "part", },
            .{ .color = "1;90" },
        },
        .{
            &.{ "bak" },
            .{ .color = "0;36" },
        },

    }) |set| for (set[0]) |ext| {
        res = res ++ .{ .{ ext, set[1] } };
    };
    break :blk std.StaticStringMapWithEql(V, std.ascii.eqlIgnoreCase).initComptime(res);
};
