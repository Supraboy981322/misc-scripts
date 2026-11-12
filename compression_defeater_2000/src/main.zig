const std = @import("std");

var quit:std.atomic.Value(bool) = .init(false);

pub fn main(init:std.process.Init) !u8 {
    var stdout_buf:["\x1B[38;2;255;255;255m~".len]u8 = undefined;
    var stdout_wr = std.Io.File.stdout().writer(init.io, &stdout_buf);
    var stdout = &stdout_wr.interface;
    var sigact:std.posix.Sigaction = .{
        .handler = .{ .handler = sig_handler },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    };
    std.posix.sigaction(std.posix.SIG.INT, &sigact, null);
    std.posix.sigaction(std.posix.SIG.TERM, &sigact, null);
    const fd = std.Io.File.stdout().handle;
    const termios = try std.posix.tcgetattr(fd);
    var raw = termios;
    raw.lflag.ICANON = false;
    raw.lflag.ECHO = false;
    try std.posix.tcsetattr(fd, .FLUSH, raw);
    defer cleanup(termios, stdout);
    var fut = try init.io.concurrent(keys, .{ init.io, stdout });
    defer if (!quit.load(.seq_cst)) fut.cancel(init.io) catch {};
    while (!quit.load(.seq_cst)) {
        var buf:[4]u8 = undefined;
        init.io.random(&buf);
        buf[3] = '0' + (buf[3] % (('~' + 1) - '0'));
        const r, const g, const b, const c = buf;
        try stdout.print("\x1B[38;2;{d};{d};{d}m{c}", .{r, g, b, c});
        try stdout.flush();
    }
    return 0;
}

fn cleanup(og:std.posix.termios, stdout:*std.Io.Writer) void {
    const fd = std.Io.File.stdin().handle;
    std.posix.tcsetattr(fd, .FLUSH, og) catch {};
    stdout.print("\x1b[?1049l\x1b[0m\x1B[2K\nexiting...\n", .{}) catch {};
    stdout.flush() catch {};
    std.process.exit(0);
}

pub fn keys(io:std.Io, stdout:*std.Io.Writer) !void {
    try stdout.print("\x1b[?1049h", .{});
    try stdout.flush();
    var buf:[1]u8 = undefined;
    var stdin_re = std.Io.File.stdin().reader(io, &buf);
    var stdin = &stdin_re.interface;
    while (!quit.load(.seq_cst)) {
        switch (try stdin.takeByte()) {
            'q' => quit.store(true, .seq_cst),
            else => {},
        }
    }
}

fn sig_handler(_:std.posix.system.SIG) callconv(.c) void {
    quit.store(true, .seq_cst);
}
