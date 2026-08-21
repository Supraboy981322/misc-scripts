const std = @import("std");

pub var do_verbose:bool = false;
pub var be_silent:bool = false;

var mut:std.Io.Mutex = .init;
var io:std.Io = undefined;
pub fn init(junk:std.process.Init) !void {
    io = junk.io;
}

fn mkTag(src:std.builtin.SourceLocation) []const u8 {
    comptime for (src.fn_name, 0..) |b, i| {
        if (b == '_') return src.fn_name[0..i];
    } else
        unreachable;
}

fn generic(comptime tag:[]const u8, comptime msg:[]const u8, stuff:anytype) !void {
    try mut.lock(io);
    defer mut.unlock(io);
    var buf:[1024]u8 = undefined;
    var stderr = std.Io.File.stderr().writer(io, &buf);
    const line = "[" ++ tag ++ "]: " ++ msg ++ "\n";
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
pub fn file(comptime msg:[]const u8, stuff:anytype) !void {
    if (!do_verbose) return;
    try generic(mkTag(@src()), msg, stuff);
}
pub fn dir(comptime msg:[]const u8, stuff:anytype) !void {
    if (!do_verbose) return;
    try generic(mkTag(@src()), msg, stuff);
}
pub fn err(comptime msg:[]const u8, stuff:anytype) !void {
    try generic(mkTag(@src()), msg, stuff);
}
pub fn skip(comptime which:std.Io.File.Kind, name:[]const u8) !void {
    if (!do_verbose) return;
    try generic(mkTag(@src()) ++ "ping (" ++ @tagName(which) ++ ")", "{s}", .{name});
}
pub fn new(comptime which:std.Io.File.Kind, name:[]const u8) !void {
    if (!do_verbose) return;
    const tag = if (which == .file) "counting" else "recursing";
    try generic(tag, "{s}", .{name});
}
