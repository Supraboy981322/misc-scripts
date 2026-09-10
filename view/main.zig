const std = @import("std");

var paths:std.ArrayList([]const u8) = .empty;

// NOTE: this struct is parsed via a comptime block to generate the help info
const opts = struct {
    pub var l = false; //include entry stat in directory listing
    pub var a = false; //list all (directory listings)
    pub var D = false; //default to directory listing
    pub var C = false; //always print color
    pub var N = false; //don't print paths for multiple inputs
};

var term_width:usize = 0;
var term_color:bool = false;

pub fn main(init:std.process.Init) !u8 {
    defer paths.deinit(init.gpa);
    try doArgs(init);

    var out_buf:[1024]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(init.io, &out_buf);
    term_width = blk: {
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
    term_color = blk: {
        const no_color = init.environ_map.get("NO_COLOR") != null;
        const tty = std.Io.File.stdout().isTty(init.io) catch false;
        break :blk (!no_color and tty) or opts.C;
    };

    var in_buf:[1024]u8 = undefined;
    const many = paths.items.len > 1;

    while (paths.pop()) |raw_path| {
        var path = raw_path;
        _ = &path;
        if (many and !opts.N) {
            try stdout.interface.print("\n{s}:\n", .{path});
            try stdout.interface.flush();
        }
        errdefer std.log.info("at path |{s}|", .{path});
        const path_stat = try std.Io.Dir.cwd().statFile(init.io, path, .{});
        switch (path_stat.kind) {

            .directory => try doDir(init, path, &stdout.interface),

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

pub fn doDir(init:std.process.Init, path:[]const u8, stdout:*std.Io.Writer) !void {
    var dir = try std.Io.Dir.cwd().openDir(init.io, path, .{ .iterate = true });
    var itr = try dir.walkSelectively(init.gpa);
    defer itr.deinit();

    var count:usize = 0;
    var longest:usize = 0;
    while (try itr.next(init.io)) |entry| {
        if (entry.basename.len > 0 and entry.basename[0] == '.' and !opts.a) continue;
        longest = @max(entry.basename.len + 2, longest);
        count += 1;
    }
    itr.deinit();
    itr = try dir.walkSelectively(init.gpa);

    var col:usize = 0;
    var pos:usize = 0;
    while (try itr.next(init.io)) |entry| : (pos += 1) {
        if (entry.basename.len > 0 and entry.basename[0] == '.' and !opts.a) continue;
        errdefer {
            stdout.writeByte('\n') catch {};
            stdout.flush() catch {};
            std.log.info("at entry |{s}|", .{entry.basename});
        }
        const entry_stat = try dir.statFile(init.io, entry.basename, .{
            .follow_symlinks = false
        });

        if (opts.l) {
            const template = "\x1b[0;30m-";
            var i:@Vector(3, usize) = .{ 2, 5, if (term_color) 7 else 0 };
            const style = 0;
            const color = 1;
            const char  = 2;

            var buf = stdout.buffer[0..if (term_color) template.len * 10 else 10];
            stdout.end = buf.len;
            if (term_color)
                @memcpy(buf, template ** 10)
            else
                @memset(buf, '-');

            if (term_color) buf[i[style]] = '1';
            if (entry.kind != .file) {
                if (term_color) buf[i[color]] = '4';
                buf[i[char]] = switch(entry.kind) {
                    .directory => 'd',
                    .sym_link => 'l',
                    .named_pipe => 'p',
                    .character_device => 'c',
                    .block_device => 'b',
                    .unix_domain_socket => 's',
                    else => '?',
                };
            } else if (term_color) {
                buf[i[color]-1] = '9';
            }

            const m = entry_stat.permissions.toMode();
            const S = std.posix.S;
            const table = [_]struct{ s:u4, o:struct{ s:@TypeOf(m), b:u8 } }{
                .{ .s = 0, .o = .{ .s = S.ISUID, .b = 's' } },
                .{ .s = 3, .o = .{ .s = S.ISGID, .b = 's' } },
                .{ .s = 6, .o = .{ .s = S.ISVTX, .b = 't' } },
            };
            for (table) |thing| inline for (0..3) |j| {
                i += @splat(if (term_color) template.len else 1);
                const mask = @as(u9, 0b100_000_000) >> @intCast(thing.s + j);
                const s = (m & mask) != 0;
                const o = if (j == 2) (m & thing.o.s) != 0 else false;
                if (!(s != o or (s and o))) {
                    if (term_color) {
                        buf[i[style]] = '1';
                        buf[i[color]-1] = '9';
                    }
                } else if (j < 2) {
                    buf[i[char]], const c = switch (j) {
                        0 => .{ 'r', '3' },
                        1 => .{ 'w', '1' },
                        else => comptime unreachable,
                    };
                    if (term_color) buf[i[color]] = c;
                } else {
                    buf[i[char]] =
                        if (s)
                            ([_]u8{'x', thing.o.b})[@intFromBool(o)]
                        else
                            thing.o.b - 32;
                    if (term_color)
                        buf[i[color]] = if (o) '5' else '2';
                }
            };

            if (term_color)
                try stdout.writeAll("\x1b[0m ")
            else
                try stdout.writeByte(' ');
        }

        const ext = blk: {
            const e = std.fs.path.extension(entry.basename);
            break :blk e[@min(e.len-|1, 1)..e.len];
        };
        if (term_color) {
            try stdout.print("\x1b[{s}m{s}\x1b[0m", .{
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
        } else {
            try stdout.writeAll(entry.basename);
        }
        col += 1;
        if (opts.l or col > ((term_width / longest)-|1) or pos >= count-1) {
            col = 0;
            try stdout.writeByte('\n');
        } else if (pos < count-1) {
            const len = longest - (entry.basename.len);
            _ = try stdout.splatByte(' ', len);
        }
        try stdout.flush();
    }
    try stdout.flush();
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
                'C' => opts.C = true,
                'N' => opts.N = true,
                '-' => ignore_rest = true,
                'h' => try help(init),
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

pub fn help(init:std.process.Init) !void {
    var buf:[1024]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(init.io, &buf);
    const info = comptime blk: {
        @setEvalBranchQuota((1<<32)-1);
        const trim = (struct {
            pub fn trim(str:[]const u8) []const u8 {
                return std.mem.trim(u8, str, &std.ascii.whitespace);
            }
        }).trim;
        const T = struct{ a:[]const u8, desc:[]const u8 };
        var res:[]const T = &.{};
        const src = @embedFile(@src().file);
        var itr = std.mem.tokenizeAny(u8, src, " \t" ++ ";:");
        var started:bool = false;
        done: while (itr.next()) |thing| {
            if (!started) {
                if (!std.mem.eql(u8, thing, "opts")) continue;
                started = true;
                std.debug.assert(std.mem.eql(u8, trim(itr.next().?), "="));
                std.debug.assert(std.mem.eql(u8, trim(itr.next().?), "struct"));
                std.debug.assert(std.mem.eql(u8, trim(itr.next().?), "{"));
                continue;
            } else {
                if (std.mem.eql(u8, trim(thing), "}")) break;
                if (!std.mem.eql(u8, trim(thing), "pub"))
                    {@panic("|" ++ trim(thing) ++ "|");}
                std.debug.assert(std.mem.eql(u8, trim(thing), "pub"));
                std.debug.assert(std.mem.eql(u8, trim(itr.next().?), "var"));
                const name = itr.next().?;
                std.debug.assert(std.mem.eql(u8, trim(itr.next().?), "="));
                _ = itr.next();
                var comment:[]const u8 = &.{};
                while (true) {
                    const chunk = trim(itr.next().?);
                    if (chunk.len > 1 and chunk[0] == '/' and chunk[1] == '/') {
                        comment = comment ++ chunk[2..];
                        break;
                    }
                }
                while (true) {
                    const chunk = itr.next().?;
                    comment = comment ++ " ";
                    if (std.mem.findScalar(u8, chunk, '\n')) |end| {
                        comment = comment ++ trim(chunk[0..end]);
                        if (std.mem.findScalar(u8, chunk[end..], '}') != null) break :done;
                        break;
                    }
                    comment = comment ++ trim(chunk);
                }
                res = res ++ .{ T{ .a = name, .desc = comment } };
            }
        }
        break :blk res;
    };
    for (info) |thing| {
        try stdout.interface.print("-{s}\n   {s}\n", .{thing.a, thing.desc});
    }
    try stdout.interface.flush();
    std.process.exit(0);
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
