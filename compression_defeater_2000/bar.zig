const std = @import("std");

var stdout_buf:[1024]u8 = undefined;
var stdout_wr = std.fs.File.stdout().writer(&stdout_buf);
const stdout = &stdout_wr.interface;

pub fn main() !void {
    //some ascii chars to index into
    const chars:[]const u8 = "qwertzuiopasdfghjklyxcvbnm" 
            ++ ",./;'[]\\`1234567890-=+_~!@#$%^&*(){}|:\"><?";
    //spawn a thread for listening to key presses
    const t = try std.Thread.spawn(.{}, keys, .{});
    t.detach();

    //pseudo random 
    const rand = std.crypto.random;
    while (true) {
        //random char
        const c = chars[rand.intRangeAtMost(usize, 0, chars.len-1)];
        //random number for ansi color
        const r = rand.intRangeAtMost(usize, 0, 255);
        const g = rand.intRangeAtMost(usize, 0, 255);
        const b = rand.intRangeAtMost(usize, 0, 255);
        //print the char and the ansi sequence
        try stdout.print("\x1b[38;2;{d};{d};{d}m{c}\x1b[0m", .{r, g, b, c});
        try stdout.flush();
    }
}

pub fn keys() !void { 
    //get stdin (and the file discriptor)
    var buf:[1]u8 = undefined;
    var stdin_re = std.fs.File.stdin().reader(&buf);
    var stdin = &stdin_re.interface;
    const fd = std.fs.File.stdin().handle;

    //prep terminal
    const termios = try std.posix.tcgetattr(fd);
    const og_term_state = termios; //save initial state
    var raw = og_term_state;
    raw.lflag.ICANON = false;
    raw.lflag.ECHO = false;
    try std.posix.tcsetattr(fd, .FLUSH, raw);

    //infinitely listen to keypresses
    loop: while (true) {
        switch (try stdin.takeByte()) {
            'q' => break :loop, //break loop to cleanup when 'q' pressed 
            else => {}, //ignore everything else
        }
    }
    //reset term state and exit
    try std.posix.tcsetattr(fd, .FLUSH, og_term_state);
    std.process.exit(0);
}
