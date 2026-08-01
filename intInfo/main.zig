const std = @import("std");


var which:?enum{ min, minInt, max, maxInt } = null;
var is_alias:bool = false;
var args:[]const [*:0]const u8 = undefined;

const Int = std.math.big.int.Managed;

const assert = std.debug.assert;
const stringToEnum = std.meta.stringToEnum;
const span = std.mem.span;

var threaded = std.Io.Threaded.init_single_threaded;
var io:std.Io = threaded.io();
const alloc = std.heap.page_allocator; //really, I don't need anything else for this


pub fn main(stuff:std.process.Init.Minimal) !u8 {
    args = stuff.args.vector;

    which = blk: {
        const W = @typeInfo(@TypeOf(which)).optional.child;
        const argv0 = std.fs.path.basename(span(args[0]));
        if (stringToEnum(W, argv0)) |w| {
            is_alias = true;
            break :blk w;
        }
        if (args.len < 2) return needArgs(false);
        const w = stringToEnum(W, span(args[1])) orelse return invalid();
        if (args.len < 3) return try needArgs(true);
        break :blk w;
    };

    if (args.len < 2) return try needArgs(false);

    const thing = try alloc.dupe(u8, span(args[if (is_alias) 1 else 2]));
    defer alloc.free(thing);
    if (thing.len < 2) return try invalid();

    const sign:u1 = switch (thing[0]) {
        'u' => 0,
        's', 'i', => 1,
        else => return try invalid(),
    };

    var bits:usize = 0;
    for (thing[1..]) |b| {
        if (!std.ascii.isDigit(b)) return try invalid();
        bits = (bits * 10) + (b-'0');
    }
    if (bits == 0 or (which == .min and sign == 0)) {
        try print("0\n", .{});
        return 0;
    }

    const str = sw: switch (which.?) {
        .max, .maxInt => {
            assert(bits > 0);
            var max:Int = try .init(alloc);
            defer max.deinit();
            var one:Int = try .initSet(alloc, 1);
            defer one.deinit();
            try max.shiftLeft(&one, bits - sign);
            try max.sub(&max, &one);
            break :sw try max.toString(alloc, 10, .lower);
        },
        .min, .minInt => {
            assert(bits > 0 and sign == 1);
            var min:Int = try .init(alloc);
            defer min.deinit();
            var one:Int = try .initSet(alloc, 1);
            defer one.deinit();
            try min.shiftLeft(&one, bits - 1);
            min.negate();
            break :sw try min.toString(alloc, 10, .lower);
        },
    };
    defer alloc.free(str);
    try print("{s}\n", .{str});

    return 0;
}

pub fn eprint(comptime msg:[]const u8, stuff:anytype) !void {
    var buf:[1024]u8 = undefined;
    var stderr_wr = std.Io.File.stderr().writer(io, &buf);
    const stderr = &stderr_wr.interface;
    try stderr.print(msg, stuff);
    try stderr.flush();
}

pub fn print(comptime msg:[]const u8, stuff:anytype) !void {
    var buf:[1024]u8 = undefined;
    var stdout_wr = std.Io.File.stdout().writer(io, &buf);
    const stdout = &stdout_wr.interface;
    try stdout.print(msg, stuff);
    try stdout.flush();
}

fn invalid() !u8 {
    if (which) |_| {
        try eprint("invalid integer type (expected the format (eg) u32 or i32/s32)", .{});
        return 1;
    }
    try eprint(
        \\unknown info ({s})
        \\  expected one of:
    ++ comptime blk: {
        var buf:[]const u8 = &.{};
        const W = @typeInfo(@TypeOf(which)).optional.child;
        for (std.meta.tags(W)) |tag|
            buf = buf ++ "\n    - " ++ @tagName(tag) ++ " (or " ++ @tagName(tag) ++ "Int)";
        break :blk buf ++ "\n";
    }, .{args[1]});
    return 1;
}

fn needArgs(have_which:bool) !u8 {
    try eprint("not enough args\n",.{});
    if (which != null or have_which)
        try eprint("  need an integer type (eg u32 or i32/s32)", .{})
    else {
        try eprint(
            \\  need an action and an integer type
            \\    (ie: 'intInfo max u32' or 'intInfo min s19')
            \\      alternatively, if you've symlinked the binary, you can just run (eg)
            \\        'maxInt u91'
        ++ "\n", .{});
    }
    return 1;
}
