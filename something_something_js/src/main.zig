const std = @import("std");
const js_fn = @import("js_funcs.zig");
const js = @import("js.zig");

var stdout_buf:[1024]u8 = undefined;
var stdout_wr = std.fs.File.stdout().writer(&stdout_buf);
const stdout = &stdout_wr.interface;

var stderr_buf:[1024]u8 = undefined;
var stderr_wr = std.fs.File.stdout().writer(&stderr_buf);
const stderr = &stderr_wr.interface;

pub fn main() !void {
    defer stdout.flush() catch {};
    defer stderr.flush() catch {};
    var filename:?[:0]u8 = null;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    if (args.len > 1) {
        filename = args[1];
    }
    if (filename) |fN| {
        const fi = std.fs.cwd().openFile(fN, .{}) catch |e| {
            defer stderr.flush() catch {};
            switch (e) {
                error.FileNotFound => try stderr.print("file not found\n", .{}),
                else => try stderr.print("err opening file: {t}\n", .{e}),
            }
            return;
        }; defer fi.close();

        const stat = try fi.stat();
        const si:usize = @intCast(stat.size);

        const raw = try fi.readToEndAlloc(alloc, si);
        defer alloc.free(raw); 

        const code = try alloc.dupeZ(u8, raw);
        defer alloc.free(code);
        const fns = [_]js.func{
            .{ .name = "print", .func = js_fn.print },
        };
        const s:*js.State = try js.State.new(null, fns.len, &fns);
//        defer js.mu.js_freestate(s.mujs);
        const ret = js.run.c_str(s, code);
        if (ret != 0) {
            try stderr.flush();
            try stdout.flush();
            std.process.exit(ret);
        }
    } else repl.start(); 
}
