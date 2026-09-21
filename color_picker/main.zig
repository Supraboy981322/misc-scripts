const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const input_buffers = struct {
    const bin_len = "0b_0_0_0_0_0_0_0_0_".len;

    pub var int:Buf(bin_len * @sizeOf(u32)) = .{};
    pub const rgb = struct {
        pub var r:Buf(bin_len) = .{};
        pub var g:Buf(bin_len) = .{};
        pub var b:Buf(bin_len) = .{};
        pub var a:Buf(bin_len) = .{};
    };

    fn Buf(len:usize) type {
        return struct {
            buf:[len:0]u8 = @splat(0),
            end:usize = 0,
            pub fn str(self:*@This()) [:0]const u8 {
                @memset(self.buf[self.end..], 0);
                return self.buf[0..self.end:0];
            }
        };
    }
};

var active_field:union(enum) {
    int,
    rgb:std.meta.DeclEnum(input_buffers.rgb),
    exit,
} = .int;

pub fn main(_:std.process.Init) !u8 {
    rl.SetConfigFlags(rl.FLAG_WINDOW_TRANSPARENT);
    rl.InitWindow(500, 500, "color picker");
    defer rl.CloseWindow();
    while (!rl.WindowShouldClose()) {
        tickInput();
        draw();
    }
    return 0;
}

inline fn draw() void {
    rl.BeginDrawing();
    defer rl.EndDrawing();

    var n:u32 = 0;
    var y:c_int = rl.GetScreenHeight() - 20;
    result: {
        switch (active_field) {
            .int => {
                var b = input_buffers.int;
                n = std.fmt.parseInt(u32, b.buf[0..b.end], 0) catch |err| {
                    rl.DrawText(@errorName(err), 10, y, 10, rl.RED);
                    y += 20;
                    break :result;
                };
            },
            .rgb => {
                inline for (&.{
                    input_buffers.rgb.r,
                    input_buffers.rgb.g,
                    input_buffers.rgb.b,
                    input_buffers.rgb.a
                }) |b| {
                    n = (n << 8) | (std.fmt.parseInt(u8, b.buf[0..b.end], 0) catch |err| {
                        rl.DrawText(@errorName(err), 10, y, 10, rl.RED);
                        y += 20;
                        break :result;
                    });
                }
                var a = n;
                input_buffers.int.end = 0;
                while (n > 0) : ({
                    a >>= 4;
                    input_buffers.int.end += 1;
                }) {
                    input_buffers.int.buf[input_buffers.int.end] = @intCast(switch (a & 0x0F) {
                        0...9 => a + '0',
                        10...15 => (a - 10) + 'a',
                        else => unreachable,
                    });
                }
            },
            .exit => break :result,
        }
    }

    rl.ClearBackground(.{
        .r = @truncate((n >> (8 * 3)) & 0xFF),
        .g = @truncate((n >> (8 * 2)) & 0xFF),
        .b = @truncate((n >> (8 * 1)) & 0xFF),
        .a = @truncate((n >> (8 * 0)) & 0xFF),
    });

    y = 10;
    var x:c_int = 0;
    var txt:[*c]const u8 = undefined;
    var len:c_int = 0;
    {
        txt = "color picker";
        len = rl.MeasureText(txt, 30);
        x = @divTrunc(rl.GetScreenWidth()-len, 2);
        rl.DrawText(txt, x, y, 30, rl.WHITE);
        y += 30;
    }

    {
        txt = "int";
        len = rl.MeasureText(txt, 20);
        x = @divTrunc(rl.GetScreenWidth()-len, 2);
        rl.DrawText(txt, x, y, 20, rl.WHITE);
        y += 20;

        rl.DrawRectangle(10, y, rl.GetScreenWidth()-20, y+15, rl.WHITE);
        rl.DrawText(input_buffers.int.str(), 10, y, 20, rl.BLACK);
        y += 40;
    }

    {
        txt = "rgb";
        len = rl.MeasureText(txt, 20);
        x = @divTrunc(rl.GetScreenWidth()-len, 2);
        rl.DrawText(txt, x, y, 20, rl.WHITE);
        y += 20;

        inline for ("rgba") |w| {
            txt = @as([:0]const u8, &.{w});
            len = rl.MeasureText(txt, 20);
            x = @divTrunc(rl.GetScreenWidth()-len, 2);
            rl.DrawText(txt, 10, y, 20, rl.WHITE);

            //rl.DrawRectangle(20, y, rl.GetScreenWidth()-40, y+15, rl.WHITE);
            rl.DrawText(@field(input_buffers.rgb, &.{w}).str(), 20, y, 20, rl.BLACK);
            y += 20;
        }
        y += 20;
    }
}

inline fn tickInput() void {
    while (true) {
        const b:u8 = @intCast(rl.GetCharPressed());
        if (b == 0) break;
        switch (active_field) {
            .int => {
                if (input_buffers.int.end >= input_buffers.int.buf.len) break;
                input_buffers.int.buf[input_buffers.int.end] = b;
                input_buffers.int.end += 1;
            },
            else => unreachable, // TODO
        }
    }
}
