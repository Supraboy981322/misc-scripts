const std = @import("std");
const log = @import("log.zig");

var stuff:std.process.Init = undefined;
var counter:std.atomic.Value(usize) = .init(0);
var starting_dirs:std.ArrayList([]const u8) = .empty;
var pattern:[]const u8 = "*";

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
        wg.async(stuff.io, recurseShim, .{dir});
    }
    try wg.await(stuff.io);

    {
        var buf:[1024]u8 = undefined;
        var stdout = std.Io.File.stdout().writer(stuff.io, &buf);
        try stdout.interface.print("{s}{d}\n", .{
            if (!log.be_silent) "counted: " else "",
            counter.load(.seq_cst)
        });
        try stdout.interface.flush();
    }

    return 0;
}

pub fn recurseShim(dir:std.Io.Dir) std.Io.Cancelable!void {
    recurse(dir) catch |err| {
        try log.err("{t}", .{err});
        return error.Canceled;
    };
}

pub fn recurse(dir:std.Io.Dir) !void {
    defer dir.close(stuff.io);
    var wg:std.Io.Group = .init;
    defer wg.cancel(stuff.io);
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
            wg.async(stuff.io, recurseShim, .{d});
        },
        inline else => |tag| {
            try log.skipping(tag, entry.name);
        },
    };
    try wg.await(stuff.io);
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
        else => {
            std.log.info("this -> |{c}|", .{b});
            return error.UnknownArgument;
        }
    };
}
