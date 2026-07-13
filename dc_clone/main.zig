const std = @import("std");

const isDigit = std.ascii.isDigit;
const isWhitespace = std.ascii.isWhitespace;
const isHex = std.ascii.isHex;
const exit = std.process.exit;
const int = std.math.big.int.Managed;

var io:std.Io = undefined;

var stack:[256]int = undefined;
var stack_top:[*]int = stack[0..].ptr;
var pos:usize = 0;

var registers = [_]int{undefined} ** 16;

fn push(num:int) void {
    pos += 1;
    if (pos > stack.len) @panic("stack overflow");
    stack_top[0] = num;
    stack_top += 1;
}
fn pop() ?int {
    if (pos == 0) return null;
    pos -= 1;
    stack_top -= 1;
    return stack_top[0];
}
fn getReg(reader:*std.Io.Reader) !*int {
    var buf:[2]u8 = .{0, 0};
    for (&buf) |*b| {
        while (isWhitespace(try reader.peekByte())) reader.toss(1);
        b.* = try reader.takeByte();
    }
    if (buf[0] != 'r' or !isHex(buf[1]))
        return error.InvalidRegister;
    const num = switch (buf[1]) {
        '0'...'9' => |n| n-'0',
        'a'...'f' => |n| n-'a'+10,
        else => unreachable,
    };
    return @ptrCast(registers[num..].ptr);
}

pub fn main(init:std.process.Init) !u8 {
    const alloc = init.arena.allocator();
    defer _ = init.arena.deinit();
    io = init.io;

    for (&registers) |*reg| reg.* = try .init(alloc);
    for (&stack) |*i| i.* = try .init(alloc);
    defer {
        for (&registers) |*reg| reg.deinit();
        for (&stack) |*i| i.deinit();
    }

    var in_buf:[1024]u8 = undefined;
    var stdin = std.Io.File.stdin().reader(init.io, &in_buf);
    const reader = &stdin.interface;

    while (reader.takeByte()) |b| {
        if (isWhitespace(b)) continue;

        switch (b) {
            'q' => exit(0),

            'p' => {
                if (pos == 0) {
                    try print(.err, "stack empty");
                    continue;
                }
                var num = (stack_top-1)[0];
                const str = try num.toString(alloc, 10, .lower);
                defer alloc.free(str);
                try print(.out, str);
            },

            's' => {
                var reg = try getReg(reader);
                var num = pop() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer num.deinit();
                reg.swap(&num);
            },

            't' => {
                var n = pop() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                n.deinit();
            },

            'g' => {
                const reg = try getReg(reader);
                push(reg.*);
            },

            '+' => {
                var one = pop() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer one.deinit();
                var two = pop() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer two.deinit();
                var new:int = try .init(alloc);
                try new.add(&one, &two);
                push(new);
            },
            '-' => {
                var one = pop() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer one.deinit();
                var two = pop() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer two.deinit();
                var new:int = try .init(alloc);
                try new.sub(&one, &two);
                push(new);
            },
            '*' => {
                var one = pop() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer one.deinit();
                var two = pop() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer two.deinit();
                var new:int = try .init(alloc);
                try new.mul(&one, &two);
                push(new);
            },
            '/' => {
                var one = pop() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer one.deinit();
                var two = pop() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer two.deinit();
                var new:int = try .init(alloc);
                var rem:int = try .init(alloc);
                defer rem.deinit();
                try new.divTrunc(&rem, &one, &two);
                push(new);
            },

            '0'...'9' => |n| {
                var buf:std.ArrayList(u8) = .empty;
                defer buf.deinit(alloc);
                try buf.append(alloc, n);
                while (isDigit(reader.peekByte() catch 0))
                    try buf.append(alloc, try reader.takeByte());
                var num:int = try .initSet(alloc, 0);
                try num.setString(10, buf.items);
                push(num);
            },

            else => try print(.err, "unknown op"),
        }
    } else |err| return err;

    return 0;
}

fn print(where:enum{out, err}, str:[]const u8) !void {
    var out_buf:[1024]u8 = undefined;
    var wr = switch (where) {
        .out => std.Io.File.stdout().writer(io, &out_buf),
        .err => std.Io.File.stderr().writer(io, &out_buf),
    };
    try wr.interface.print("{s}\n", .{str});
    try wr.interface.flush();
}
