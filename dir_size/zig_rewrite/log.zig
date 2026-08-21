const std = @import("std");

pub var do_verbose:bool = false;
pub var be_silent:bool = false;

var mut:std.Io.Mutex = .init;
var io:std.Io = undefined;
pub fn init(junk:std.process.Init) !void {
    io = junk.io;
}

fn mkTag(src:std.builtin.SourceLocation) []const u8 {
    comptime {
        const str = for (src.fn_name, 0..) |b, i| {
            if (b == '_') break src.fn_name[0..i];
        } else
            unreachable;
        const tag = std.meta.stringToEnum(std.meta.DeclEnum(@This()), str).?;
        const color = switch (tag) {
            .err => "31",
            .info => "32",
            .warn => "33",
            .verbose => "34",
            .skipping => "35",
            .new => "36",
            else => unreachable,
        };
        return "\x1b[" ++ color ++ "m" ++ str ++ "\x1b[0m";
    }
}

fn generic(comptime tag:[]const u8, comptime msg:[]const u8, stuff:anytype) !void {
    try mut.lock(io);
    defer mut.unlock(io);
    var buf:[1024]u8 = undefined;
    var stderr = std.Io.File.stderr().writer(io, &buf);
    const line = "\x1b[90m[\x1b[0m" ++ tag ++ "\x1b[90m]:\x1b[0m " ++ msg ++ "\n";
    stderr.interface.print(line, stuff) catch return;
    stderr.interface.flush() catch return;
}

pub fn verbose(comptime msg:[]const u8, stuff:anytype) !void {
    if (!do_verbose) return;
    try generic(mkTag(@src()), msg, stuff);
}
pub fn info(comptime msg:[]const u8, stuff:anytype) !void {
    if (be_silent) return;
    try generic(mkTag(@src()), msg, stuff);
}
pub fn warn(comptime msg:[]const u8, stuff:anytype) !void {
    if (be_silent) return;
    try generic(mkTag(@src()), msg, stuff);
}
pub fn err(comptime msg:[]const u8, stuff:anytype) !void {
    try generic(mkTag(@src()), msg, stuff);
}
pub fn skipping(comptime which:std.Io.File.Kind, name:[]const u8) !void {
    if (!do_verbose) return;
    const tag = " \x1b[90m(\x1b[0;33m" ++ @tagName(which) ++ "\x1b[90m)\x1b[0m";
    try generic(mkTag(@src()) ++ tag, "{s}", .{name});
}
pub fn new(comptime which:std.Io.File.Kind, name:[]const u8) !void {
    if (!do_verbose) return;
    const tag = "\x1b[36m" ++ (if (which == .file) "counting" else "recursing") ++ "\x1b[0m";
    try generic(tag, "{s}", .{name});
}
