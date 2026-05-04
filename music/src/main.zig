const std = @import("std");

var quit:bool = false;
var ffplay:std.posix.pid_t = undefined;

pub fn main(init:std.process.Init) !void {
    const alloc = init.gpa;

    var stdout_buf:[1024]u8 = undefined;
    var stdout_wr = std.Io.File.stdout().writer(init.io, &stdout_buf);
    const stdout = &stdout_wr.interface;

    var args = [8][]const u8 {
        "ffplay",
        "-nodisp",
        "-autoexit",
        "-hide_banner",
        "-loglevel",
        "quiet",
        "-stats",
        ""
    };

    for (args, 0..) |arg, i|
        args[i] = try alloc.dupe(u8, arg);
    defer
        for (args) |a|
            alloc.free(a);

    var upnext = try pick_item(init.io, alloc);
    defer alloc.free(upnext);
    try stdout.print("\n\n\n", .{});
    try stdout.flush();

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
    const fd = std.Io.File.stdin().handle;

    //prep terminal
    const termios = try std.posix.tcgetattr(fd);
    const og_term_state = termios; //save initial state
    var raw = og_term_state;
    raw.lflag.ICANON = false;
    raw.lflag.ECHO = false;
    try std.posix.tcsetattr(fd, .FLUSH, raw);
    defer cleanup(og_term_state, stdout);


    var key_fut = std.Io.async(init.io, keys, .{ init.io, stdout });
    defer _ = key_fut.cancel(init.io) catch |e| @panic(@errorName(e));

    while (!quit) {
        alloc.free(args[7]);
        args[7] = try alloc.dupe(u8, upnext);
        alloc.free(upnext);
        upnext = try pick_item(init.io, alloc);
        try stdout.print(
            "\x1b[3A\x1b[2K\r\x1b[33mplaying: "
                ++ "\x1b[34m{s}\x1b[0m\n\x1b[2K\t\x1b[35mupnext: "
                    ++ "\x1b[36m{s}\x1b[0m\n\x1b[2K",
            .{ args[7], upnext }
        );
        try stdout.flush();
        var ffplay_proc = try std.process.spawn(init.io, .{
            .argv = &args,
            .stdout = .pipe,
            .stderr = .pipe,
            .stdin = .pipe,
        });
        ffplay = ffplay_proc.id.?;
        _ = ffplay_proc.wait(init.io) catch |e|
            if (e != error.Canceled) @panic(@errorName(e));
    }
}

pub fn pick_item(io:std.Io, alloc:std.mem.Allocator) ![]const u8 {
    var dir = try std.Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });
    var walker = try dir.walk(alloc);
    defer walker.deinit();
    var arr = try std.ArrayList([]const u8).initCapacity(alloc, 0);
    defer {
        for (arr.items) |file|
            alloc.free(file);
        arr.deinit(alloc);
    }
    while (try walker.next(io)) |entry| if (entry.kind == .file) {
        try arr.append(alloc, try alloc.dupe(u8, entry.basename));
    };
    const random = (std.Random.IoSource{ .io = io }).interface();
    const idx = random.uintAtMost(usize, arr.items.len - 1);
    const picked = arr.items[idx];
    return alloc.dupe(u8, picked);
}

pub fn keys(io:std.Io, stdout:*std.Io.Writer) !void {

    //get stdin (and the file discriptor)
    var buf:[1]u8 = undefined;
    var stdin_re = std.Io.File.stdin().reader(io, &buf);
    var stdin = &stdin_re.interface;

    //infinitely listen to keypresses
    while (!quit) {
        switch (try stdin.takeByte()) {
            'q' => {
                for (0..2) |_|
                    try stdout.print("\x1b[A\x1b[2K\r", .{});
                try stdout.print("exiting...\n", .{});
                try stdout.flush();
                quit = true;
                try std.posix.kill(ffplay, .QUIT);
                return;
            },
            else => {}, //ignore everything else
        }
    }
}

fn cleanup(og: std.posix.termios, _:*std.Io.Writer) void {
    const fd = std.Io.File.stdin().handle;

    //reset term state
    std.posix.tcsetattr(fd, .FLUSH, og) catch {};

    std.process.exit(0);
}

fn sig_handler(_:std.posix.system.SIG) callconv(.c) void {
    quit = true;
}
