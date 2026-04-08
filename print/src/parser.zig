const std = @import("std");

const stderr = &@constCast(&std.fs.File.stderr().writer(&.{})).interface;

pub fn parse_octal(in:[]u8) u8 {
    var v:u8 = 0;
    for (in) |b| {
        if (b > '7' or b < '0') return 0;
        v *= 8;
        v += b - '0';
    }
    return v;
}

pub fn parse_hex(in:[]u8) u8 {
    var v:u8 = 0;
    for (in) |b| {
        v *= 16;
        v += switch (b) {
            '0'...'9' => b - '0',
            'a'...'f' => b - 'a' + 10,
            'A'...'F' => b - 'A' + 10,
            else =>  {
                stderr.print("invalid character in hex escape: {c}\n", .{b}) catch {};
                std.process.exit(1);
                unreachable;
            },
        };
    }
    return v;
}

pub fn parse_unicode(i:*usize, in:[]u8, alloc:std.mem.Allocator) []u8 {
    var j:usize = 0;
    defer i.* += j;
    while (j < in.len) : (j += 1)
        if (in[j] == '}') break;

    if (j == in.len) j -= 1;

    const zig_dumb = std.fmt.allocPrint(
        alloc, "\"{s}\"", .{in[0..j+1]}
    ) catch |e| @panic(@errorName(e));

    defer alloc.free(zig_dumb);

    return std.zig.string_literal.parseAlloc(alloc, zig_dumb) catch |e| {
        switch (e) {
            error.InvalidLiteral => {
                stderr.print(
                    "invalid unicode escape: {s}\n", .{zig_dumb}
                ) catch {};
                std.process.exit(1);
            },
            else => @panic(@errorName(e)),
        }
    };
}

pub fn parse_literal(alloc:std.mem.Allocator, in:[]u8) ![]u8 {
    var arr = try std.ArrayList(u8).initCapacity(alloc, 0);
    defer _ = arr.deinit(alloc);
    var esc:bool = false;
    var i:usize = 0;
    loop: while (i < in.len) : (i += 1) {
        const b = in[i];
        if (esc) {
            esc = !esc;
            try arr.append(alloc, switch (b) {
                'n' => '\n', //newline
                'r' => '\r', //carrage return
                't' => '\t', //tab

                //every modern language should have these built-in
                //  (some of Zig's decisions are quite strange, in my opinion)
                'e' => '\x1b', //escape character
                'a' => '\x07', //bell character
                'b' => '\x08', //backspace
                'f' => '\x0c', //formfeed
                'v' => '\x0b', //vertical tab

                //\xXX for hex
                'x', 'X' => block: {
                    if (in[i..].len < 2) {
                        stderr.print(
                            \\invalid hex escape:
                            \\  expected 2 valid hex chars following '\\x' but found {d}
                            ++ "\n", .{in[i..].len}
                        ) catch {};
                        std.process.exit(1);
                    }
                    defer i += 2;
                    break :block parse_hex(in[i+1..i+3]);
                },
                
                '0', 'o' => block: {
                    defer i += 2;
                    if (in[i] == 'o') i += 1;
                    break :block if (in[i..].len >= 3) 
                        parse_octal(in[i..i+3])
                    else
                        0;
                },

                'u' => {
                    i -= 1;
                    const foo = parse_unicode(&i, in[i..], alloc);
                    try arr.appendSlice(alloc, foo);
                    alloc.free(foo);
                    continue :loop;
                },

                else => b,
            });
            continue :loop;
        }
        switch (b) {
            '\\' => esc = true,
            else => try arr.append(alloc, b),
        }
    }
    return try arr.toOwnedSlice(alloc);
}
