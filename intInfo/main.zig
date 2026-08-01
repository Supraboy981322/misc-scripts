const std = @import("std");

var threaded = std.Io.Threaded.init_single_threaded;
var io:std.Io = threaded.io();
const alloc = std.heap.page_allocator; //really, I don't need anything else for this
const Int = std.math.big.int.Managed;
var which:enum{ min, max } = .max;

pub fn main(stuff:std.process.Init.Minimal) !u8 {

    if (stuff.args.vector.len != 2) {
        if (stuff.args.vector.len < 2)
            try eprint("not enough args (need exactly one)\n", .{})
        else
            try eprint("too many args (need exactly one)\n", .{});
        return 1;
    }

    const thing = try alloc.dupe(u8, std.mem.span(stuff.args.vector[1]));
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
    if (bits == 0) {
        try print("0\n", .{});
        return 0;
    }

    // TODO: this can (probably) be done fast (with less memory chunked
    //   (printing each chunk to terminal)
    const str = sw: switch (which) {
        .max => {
            var max:Int = try .init(alloc);
            defer max.deinit();
            var one:Int = try .initSet(alloc, 1);
            defer one.deinit();
            try max.shiftLeft(&one, bits - sign);
            try max.sub(&max, &one);
            break :sw try max.toString(alloc, 10, .lower);
        },
        .min => unreachable,
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
    try eprint("invalid integer type (expected the format (eg) u32 or i32/s32)", .{});
    return 1;
}
