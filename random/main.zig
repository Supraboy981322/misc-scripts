const std = @import("std");

// NOTE: compiles with Zig 0.16.0

const exit = std.process.exit;
const log = std.log;
const span = std.mem.span;
const parseInt = std.fmt.parseInt;
const toLower = std.ascii.toLower;
const count = std.mem.count;
const fields = std.meta.fieldNames;
var stdout = std.Io.File.stdout().writer(io, &.{});
//it's a basic throw-away script; why would this need thread-safety?
const alloc = std.heap.page_allocator;
const io = std.Io.Threaded.global_single_threaded.io();

pub fn main(
    init:std.process.Init.Minimal,
) error{
    OutOfMemory,
    WriteFailed,
    NeedLength,
    TooManyArgs,
    Overflow,
    InvalidCharacter,
} !u8 {
    var table:[]const u8 = std.ascii.letters
            ++ "0123456789;:/|!@#$%^&*()-=_+<>,.?{}[]";
    const len = len: {
        const args = init.args.vector;
        errdefer |err| abort(err, args[0]);
        if (args.len < 2) return error.NeedLength;
        if (args.len > 2) {
            if (args.len != 3) return error.TooManyArgs;
            table = span(args[2]);
        }
        break :len try parseInt(usize, span(args[1]), 0);
    };
    const buf = try alloc.alloc(u8, len);
    defer alloc.free(buf);
    io.random(buf);
    for (buf) |*b| b.* = table[b.* % table.len];
    try stdout.interface.writeAll(buf);
    return 0;
}

fn abort(err:anytype, argv0:[*c]const u8) noreturn {
    const buf_len = comptime buf: {
        var max = 0;
        for (fields(@TypeOf(err))) |name|
            max = @max(max, name.len + count(u8, name, std.ascii.uppercase) + 1);
        break :buf max + 1;
    };
    var buf:[buf_len]u8 = undefined;
    var i:usize = 0;
    for (@errorName(err)) |b| {
        defer i += 1;
        if (b >= 'a' or i == 0) {
            buf[i] = toLower(b);
            continue;
        }
        buf[i] = ' ';
        i += 1;
        buf[i] = toLower(b);
    }
    log.err("{s}", .{buf[0..i]});
    log.info("usage: {s} [length] <table>", .{argv0});
    exit(1);
}
