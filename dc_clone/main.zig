const write = @import("std").posix.system.write;
const read = @import("std").posix.system.read;
const errno = @import("std").posix.system.errno;
const fd_t = @import("std").posix.system.fd_t;

// TODO: refactor for f34

const Cmd = enum(u8) {
    exit,
    print,
    sqrt,
    add, sub,
    div, mult,
    discard,

    // TODO:
    pow,
    root,
};

var stack = [_]i32{0} ** 256;
var top:[*]i32 = undefined;
inline fn push(s:i32) void {
    top[0] = s;
    top += 1;
}
inline fn pop() i32 {
    top -= 1;
    return top[0];
}

inline fn print(msg:[]const u8) void {
    fprint(1, msg);
}
fn fprint(fd:fd_t, msg:[]const u8) void {
    const ret = write(fd, msg.ptr, msg.len);
    if (errno(ret) != .SUCCESS) @panic("failed to write to stdout");
}

pub fn main() !u8 {

    top = (&stack).ptr;
    var buf:[1024]u8 = undefined;

    while (true) {
        defer print("\n");
        print("\n\x1b[33m(?):\x1b[0m ");

        const n = read(0, &buf, 1024);
        var line = buf[0..n];

        while (shift(&line)) |word| {
            if (is_num(word))
                push(parse_num(word))
            else if (mk_cmd(word)) |cmd| {
                if (do_cmd(cmd)) return 0;
            } else {
                inline for ([_][]const u8{
                    "invalid command: |", word, "|\n"
                }) |seg|
                    fprint(2, seg);
            }
        }
    }
    return 0;
}

fn do_cmd(cmd:Cmd) bool {
    switch (cmd) {
        inline .add, .div, .sub, .mult => |w| {
            const two = pop();
            const one = pop();
            const v = switch (comptime w) {
                .add => one + two,
                .sub => one - two,
                .div => @divTrunc(one, two),
                .mult => one * two,
                else => unreachable,
            };
            push(v);
        },
        .sqrt => push(sqrt(pop())),
        .discard => _ = pop(),
        .print => {
            var buf:[10]u8 = undefined;
            var b:[]u8 = &buf;
            to_str(&b, (top - 1)[0]);
            print(b);
        },
        .exit => return true,
        else => unreachable,
    }
    return false;
}

fn parse_num(str:[]u8) i32 {
    var res:i32 = 0;
    const s = if (str[0] == '-') str[1..] else str;
    for (s) |b| {
        res *= 10;
        res += b - '0';
    }
    if (str[0] == '-') res *= -1;
    return res;
}

inline fn sqrt(v:i32) i32 {
    return @intFromFloat(@sqrt(@as(f32, @floatFromInt(v))));
}
fn dig(v:u8) [2]u8 {
    return .{ @intCast('0' + v / 10), @intCast('0' + v % 10) };
}
fn to_str(buf:*[]u8, val:i32) void {
    const abs = @abs(val);
    var a = abs;
    var i:usize = buf.len;
    while (a >= 100) : (a = @divTrunc(a, 100)) {
        i -= 1;
        buf.*[i..][0..2].* = dig(@intCast(a % 100));
    }
    i -= 1;
    if (a < 10)
        buf.*[i] = '0' + @as(u8, @intCast(a))
    else {
        i -= 1;
        buf.*[i..][0..2].* = dig(@intCast(a));
    }

    i -= 1;
    if (val < 0) {
        buf.*[i] = '-';
    } else
        buf.* = buf.*[1..buf.len];
    buf.* = buf.*[i..];
}

inline fn is_space(b:u8) bool {
    return b == ' ' or (b >= '\t' and b <= '\r');
}
fn is_num(str:[]u8) bool {
    const s = if (str[0] == '-') str[1..] else str;
    for (s) |b| if (b < '0' or b > '9') return false;
    return true;
}
fn mk_cmd(str:[]u8) ?Cmd {
    if (str_eql_any(str, &.{ "+", "add" })) return .add;
    if (str_eql_any(str, &.{ "-", "sub" })) return .sub;
    if (str_eql_any(str, &.{ "*", "mult" })) return .mult;
    if (str_eql_any(str, &.{ "/", "div" })) return .div;
    if (str_eql_any(str, &.{ "v", "sqrt" })) return .sqrt;
    if (str_eql_any(str, &.{ "d", "discard" })) return .discard;
    if (str_eql_any(str, &.{ "p", "print" })) return .print;
    if (str_eql_any(str, &.{ "q", "exit", "quit" })) return .exit;
    return null;
}
fn str_eql(one:[]const u8, two:[]const u8) bool {
    if (one.len != two.len) return false;
    for (0..one.len) |i| if (two[i] != one[i]) return false;
    return true;
}
fn str_eql_any(str:[]const u8, comptime checks:[]const []const u8) bool {
    return inline for (checks) |chk| {
        if (str_eql(str, chk)) break true;
    } else
        false;
}


fn trim(str:*[]u8) void {
    var start:usize = 0;
    while (is_space(str.*[start])) : (start += 1) {}
    var end:usize = str.len-1;
    while (is_space(str.*[end])) : (end -= 1) {}
    str.* = str.*[start..end];
}

fn shift(string:*[]u8) ?[]u8 {
    var i:usize = 0;
    while (i < string.len) : (i += 1) {
        if (is_space(string.*[i])) {
            const word = string.*[0..i];
            while (i < string.len and is_space(string.*[i])) : (i += 1) {}
            string.* = string.*[i..];
            return word;
        }
    }
    if (string.len > 0) {
        defer string.* = string.*[0..0];
        return string.*;
    }
    return null;
}
