const std = @import("std");

var stdout_buf:[1024]u8 = undefined;
var stdout_wr = std.fs.File.stdout().writer(&stdout_buf);
const stdout = &stdout_wr.interface;

pub fn main() !void {
    const chars:[]const u8 = "qwertzuiopasdfghjklyxcvbnm" 
            ++ ",./;'[]\\`1234567890-=+_~!@#$%^&*(){}|:\"><?";
    const t = try std.Thread.spawn(.{}, keys, .{});
    t.detach();
    const r = std.crypto.random;
    while (true) {
        const c = chars[r.intRangeAtMost(usize, 0, chars.len-1)];
        const n = r.intRangeAtMost(usize, 0, 6);
        try stdout.print("\x1b[3{d}m{c}\x1b[0m", .{n, c});
        try stdout.flush();
    }
}

pub fn keys() !void { 
    var buf:[1]u8 = undefined;
    var stdin_re = std.fs.File.stdin().reader(&buf);
    var stdin = &stdin_re.interface;
    const fd = std.fs.File.stdin().handle;

    //prep terminal
    const termios = try std.posix.tcgetattr(fd);
    const og_term_state = termios;
    var raw = og_term_state;
    raw.lflag.ICANON = false;
    raw.lflag.ECHO = false;
    try std.posix.tcsetattr(fd, .FLUSH, raw);

    loop: while (true) {
        switch (try stdin.takeByte()) {
            'q' => break :loop,
            else => {},
        }
        buf = undefined;
    }
    try std.posix.tcsetattr(fd, .FLUSH, og_term_state);
    std.process.exit(0);
}
