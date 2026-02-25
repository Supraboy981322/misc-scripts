const std = @import("std");

var stdout_buf:[1024]u8 = undefined;
var stdout_wr = std.fs.File.stdout().writer(&stdout_buf);
const stdout = &stdout_wr.interface;

var quit:bool = false;

pub fn main() !void {
    //create a sigaction struct
    var sig_act = std.posix.Sigaction{
        .handler = .{ .handler = sig_handler },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    };
    //register signals
    std.posix.sigaction(std.c.SIG.INT, &sig_act, null);
    std.posix.sigaction(std.c.SIG.TERM, &sig_act, null);

    //stdin term file discriptor
    const fd = std.fs.File.stdin().handle;

    //prep terminal
    const termios = try std.posix.tcgetattr(fd);
    const og_term_state = termios; //save initial state
    var raw = og_term_state;
    raw.lflag.ICANON = false;
    raw.lflag.ECHO = false;
    try std.posix.tcsetattr(fd, .FLUSH, raw);
    defer cleanup(og_term_state);

    //some ascii chars to index into
    const chars:[]const u8 = "qwertzuiopasdfghjklyxcvbnm" 
            ++ ",./;'[]\\`1234567890-=+_~!@#$%^&*(){}|:\"><?";

    //spawn a thread for listening to key presses
    const t = try std.Thread.spawn(.{}, keys, .{});
    t.detach();

    //pseudo random 
    const rand = std.crypto.random;
    while (!quit) {
        //random char
        const c = chars[rand.intRangeAtMost(usize, 0, chars.len-1)];

        //random rgb values
        const r = rand.int(u8);
        const g = rand.int(u8);
        const b = rand.int(u8);

        //print the char and the ansi sequence
        try stdout.print(
            "\x1b[38;2;{d};{d};{d}m{c}\x1b[0m", .{r, g, b, c}
        );
        try stdout.flush();
    }
}

pub fn keys() !void { 
    //open term alt buf
    try stdout.print("\x1b[?1049h", .{});
    try stdout.flush();

    //get stdin (and the file discriptor)
    var buf:[1]u8 = undefined;
    var stdin_re = std.fs.File.stdin().reader(&buf);
    var stdin = &stdin_re.interface;

    //infinitely listen to keypresses
    while (!quit) {
        switch (try stdin.takeByte()) {
            'q' => quit = true, //break loop to cleanup when 'q' pressed 
            else => {}, //ignore everything else
        }
    }
}

fn cleanup(og: std.posix.termios) void {
    const fd = std.fs.File.stdin().handle;

    //reset term state
    std.posix.tcsetattr(fd, .FLUSH, og) catch {};

    //restore main term buf
    stdout.print("\x1b[?1049l\x1b[0m\nexiting...\n", .{}) catch {};
    stdout.flush() catch {};

    std.process.exit(0);
}

fn sig_handler(signum:i32) callconv(.c) void {
    _ = signum;
    quit = true;
}
