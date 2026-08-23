const std = @import("std");
const log = @import("log.zig");

var stuff:std.process.Init = undefined;
var counter:std.atomic.Value(usize) = .init(0);
var starting_dirs:std.ArrayList([]const u8) = .empty;
var pattern:[]const u8 = "*";
var flag_human:bool = false;

const eql = std.mem.eql;

pub fn main(init:std.process.Init) !u8 {
    stuff = init;
    defer starting_dirs.deinit(init.gpa);
    try log.init(init);
    doArgs() catch |err| {
        std.log.err("failed to parse arguments: {t}", .{err});
        return 1;
    };
    errdefer log.info("counted: {d}", .{counter.load(.seq_cst)}) catch {};
    if (starting_dirs.items.len == 0) try starting_dirs.append(stuff.gpa, ".");
    var wg:std.Io.Group = .init;
    defer wg.cancel(stuff.io);
    for (starting_dirs.items) |dirname| {
        const dir = try std.Io.Dir.cwd().openDir(stuff.io, dirname, .{ .iterate = true });
        wg.async(stuff.io, recurseShim, .{&wg, dir});
    }
    try wg.await(stuff.io);

    var buf:[1024]u8 = undefined;
    const res:[]const u8 = blk: {
        const n_buf = buf[buf.len-65..];
        if (!flag_human) {
            const end = std.fmt.printInt(n_buf, counter.load(.seq_cst), 10, .lower, .{});
            break :blk n_buf[0..end];
        }
        var n:usize = counter.load(.seq_cst);
        if (n == 0) break :blk "0 B";
        var d:usize = 0;
        var i:usize = 0;
        const table = [_][]const u8 { "B", "KB", "MB", "GB", "TB", "PB", "EB", "YB" };
        while (n > 1000) {
            if (i + 1 >= table.len) break;
            d = @rem(n, 1000);
            n /= 1000;
            i += 1;
        }
        if (d > 100) d /= 10;
        break :blk try std.fmt.bufPrint(n_buf, "{d}.{d:0>2} {s}", .{n,d, table[i]});
    };
    var stdout = std.Io.File.stdout().writer(stuff.io, buf[0..buf.len-65]);
    try stdout.interface.print("{s}{s}\n", .{
        if (!log.be_silent) "counted: " else "",
        res,
    });
    try stdout.interface.flush();

    return 0;
}

pub fn recurseShim(wg:*std.Io.Group, dir:std.Io.Dir) std.Io.Cancelable!void {
    recurse(wg, dir) catch |err| {
        try log.err("{t}", .{err});
        return error.Canceled;
    };
}

pub fn recurse(wg:*std.Io.Group, dir:std.Io.Dir) !void {
    defer dir.close(stuff.io);
    var itr = dir.iterate();
    while (try itr.next(stuff.io)) |entry| switch (entry.kind) {
        .file => {
            try log.new(.file, entry.name);
            var file = try dir.openFile(stuff.io, entry.name, .{});
            defer file.close(stuff.io);
            _ = counter.fetchAdd(try file.length(stuff.io), .seq_cst);
        },
        .directory => {
            try log.new(.directory, entry.name);
            const d = try dir.openDir(stuff.io, entry.name, .{ .iterate = true });
            wg.async(stuff.io, recurseShim, .{wg, d});
        },
        inline else => |tag| {
            try log.skipping(tag, entry.name);
        },
    };
}

pub fn doArgs() !void {
    var itr = stuff.minimal.args.iterate();
    _ = itr.skip();
    while (itr.next()) |arg| {
        errdefer std.log.info("here -> |{s}|", .{arg});
        if (arg.len > 0) if (arg[0] == '-') {
            if (arg[1] == '-')
                try flagArg(&itr, arg[2..])
            else
                try bundleArg(&itr, arg[1..]);
            continue;
        };
        try starting_dirs.append(stuff.gpa, arg);
    }
    if (log.do_verbose and log.be_silent) {
        try log.err("cannot enable both 'silent' and 'verbose'", .{});
        return error.ArgumentsClobber;
    }
}

pub fn flagArg(itr:*std.process.Args.Iterator, flag:[]const u8) !void {
    if (flag.len == 0) {
        while (itr.next()) |arg| try starting_dirs.append(stuff.gpa, arg);
        return;
    }
    if (eql(u8, flag, "verbose")) {
        log.do_verbose = true;
        return;
    }
    if (eql(u8, flag, "silent")) {
        log.be_silent = true;
        return;
    }
    if (eql(u8, flag, "pattern")) {
        pattern = itr.next() orelse {
            return error.MissingArgumentValue;
        };
        return;
    }
    if (eql(u8, flag, "human-readable")) {
        flag_human = true;
        return;
    }
    return error.UnknownArgument;
}

pub fn bundleArg(itr:*std.process.Args.Iterator, bundle:[]const u8) !void {
    if (bundle.len == 0) {
        try log.warn("reading list of directories from stdin", .{});
        var buf:[std.posix.PATH_MAX]u8 = undefined;
        var stdin = std.Io.File.stdin().reader(stuff.io, &buf);
        while (try stdin.interface.takeDelimiter('\n')) |dir| {
            try starting_dirs.append(stuff.gpa, dir);
        }
        return;
    }
    for (bundle) |b| switch (b) {
        'V' => log.do_verbose = true,
        'p' => pattern = itr.next() orelse return error.MissingArgumentValue,
        'S' => log.be_silent = true,
        'H' => flag_human = true,
        else => {
            std.log.info("this -> |{c}|", .{b});
            return error.UnknownArgument;
        }
    };
}
