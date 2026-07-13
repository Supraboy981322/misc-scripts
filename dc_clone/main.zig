const std = @import("std");

const isDigit = std.ascii.isDigit;
const isWhitespace = std.ascii.isWhitespace;
const isHex = std.ascii.isHex;
const exit = std.process.exit;
const abort = std.process.abort;
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
const Pair = struct {
    one:int,
    two:int,
    pub fn deinit(self:*Pair) void {
        self.one.deinit();
        self.two.deinit();
    }
    pub fn init(one:int, two:int) Pair {
        return .{ .one = one, .two = two };
    }
};
fn pop2() ?Pair {
    var two = pop() orelse return null;
    const one = pop() orelse {
        two.deinit();
        return null;
    };
    return .init(one, two);
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

fn print(where:enum{out, err}, str:[]const u8) !void {
    var out_buf:[1024]u8 = undefined;
    var wr = switch (where) {
        .out => std.Io.File.stdout().writer(io, &out_buf),
        .err => std.Io.File.stderr().writer(io, &out_buf),
    };
    try wr.interface.print("{s}\n", .{str});
    try wr.interface.flush();
}

pub fn main(init:std.process.Init) !u8 {
    errdefer abort();

    const alloc = init.arena.allocator();
    defer _ = init.arena.deinit();
    io = init.io;

    for (&registers) |*reg| reg.* = try .init(alloc);
    for (&stack) |*i| i.* = try .init(alloc);

    var in_buf:[1024]u8 = undefined;
    var stdin = std.Io.File.stdin().reader(init.io, &in_buf);
    const reader = &stdin.interface;

    while (reader.takeByte()) |b| {
        errdefer |e| {
            print(.err, @errorName(e)) catch {};
            exit(1);
            unreachable;
        }

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

            'g' => push((try getReg(reader)).*),

            '=' => {
                var pair = pop2() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer pair.deinit();
                const new:int = try .initSet(alloc, @intFromBool(pair.one.eql(pair.two)));
                push(new);
            },

            'x' => {
                var pair = pop2() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer pair.deinit();
                var new:int = try .initSet(alloc, 0);
                try new.bitXor(&pair.one, &pair.two);
                push(new);
            },
            '|' => {
                var pair = pop2() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer pair.deinit();
                var new:int = try .initSet(alloc, 0);
                try new.bitOr(&pair.one, &pair.two);
                push(new);
            },
            '&' => {
                var pair = pop2() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer pair.deinit();
                var new:int = try .initSet(alloc, 0);
                try new.bitAnd(&pair.one, &pair.two);
                push(new);
            },

            'R' => {
                var pair = pop2() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer pair.deinit();
                const amnt = pair.two.toInt(usize) catch {
                    try print(.err, "integer overflow");
                    continue;
                };
                var new:int = try .initSet(alloc, 0);
                try new.shiftRight(&pair.one, amnt);
                push(new);
            },
            'L' => {
                var pair = pop2() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer pair.deinit();
                const amnt = pair.two.toInt(usize) catch {
                    try print(.err, "integer overflow");
                    continue;
                };
                var new:int = try .initSet(alloc, 0);
                try new.shiftLeft(&pair.one, amnt);
                push(new);
            },

            '^' => {
                var pair = pop2() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer pair.deinit();
                const pow = pair.two.toInt(u32) catch {
                    try print(.err, "integer overflow");
                    continue;
                };
                var new:int = try .initSet(alloc, 0);
                try new.pow(&pair.one, pow);
                push(new);
            },

            '+' => {
                var pair = pop2() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer pair.deinit();
                var new:int = try .init(alloc);
                try new.add(&pair.one, &pair.two);
                push(new);
            },
            '-' => {
                var pair = pop2() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer pair.deinit();
                var new:int = try .init(alloc);
                try new.sub(&pair.one, &pair.two);
                push(new);
            },
            '*' => {
                var pair = pop2() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer pair.deinit();
                var new:int = try .init(alloc);
                try new.mul(&pair.one, &pair.two);
                push(new);
            },
            '/' => {
                var pair = pop2() orelse {
                    try print(.err, "stack empty");
                    continue;
                };
                defer pair.deinit();
                var new:int = try .init(alloc);
                var rem:int = try .init(alloc);
                defer rem.deinit();
                try new.divTrunc(&rem, &pair.one, &pair.two);
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
