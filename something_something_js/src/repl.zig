const std = @import("std");
const js = @import("js.zig");
const js_fns = @import("js_funcs.zig");
const globs = @import("globals.zig");
const hlp = @import("helpers.zig");

const stdout = globs.stdout;
const stderr = globs.stderr;
const stdin = globs.stdin;

const mu = js.mu;

pub fn start(s:js.State) void {
    var alloc = std.heap.page_allocator;

    var stop:bool = false;

    var prompt_char:[]const u8 = "?";
    while (!stop) {
        defer {
            stderr.flush() catch {};
            stdout.flush() catch {};
        }

        stdout.print("\x1b[36m({s}\x1b[36m):\x1b[0m ", .{prompt_char}) catch {};
        stdout.flush() catch {};
        prompt_char = "\x1b[32m?";

        const line = stdin.takeDelimiterExclusive('\n') catch |e| @panic(@errorName(e));
        if (std.mem.startsWith(u8, line, "quit")) stop = true else {
            const c_line = alloc.dupeZ(u8, line) catch |e| @panic(@errorName(e));
            defer alloc.free(c_line);
            
            const ret = js.run.c_str(s, c_line);
            if (ret != 0) {
                stderr.flush() catch |e| @panic(@errorName(e));
                stdout.flush() catch |e| @panic(@errorName(e));
                prompt_char = "\x1b[31m!";
            }
        }

        //discard newline
        _ = stdin.takeByte() catch |e|@panic(@errorName(e)); 
    }
}
