const std = @import("std");

const bat_uevent = "/sys/class/power_supply/BAT0/uevent";
const battery_low = (1<<5)-1;
const percent_threshold = (1<<3)-1;

const Status = enum {
    charging,
    discharging,
    pub fn fromStr(str:[]const u8) ?@This() {
        const buf_len = comptime blk: {
            var m = 0;
            for (std.meta.fieldNames(@This())) |field| m = @max(field.len, m);
            break :blk m;
        };
        var buf:[buf_len]u8 = undefined;
        if (str.len > buf.len) return null;
        for (0..str.len) |i| buf[i] = std.ascii.toLower(str[i]);
        return std.meta.stringToEnum(@This(), buf[0..str.len]);
    }
};
var status:?Status = null;

var capacity:u8 = 0;

const Level = enum {
    normal,
    pub fn fromStr(str:[]const u8) ?@This() {
        const buf_len = comptime blk: {
            var m = 0;
            for (std.meta.fieldNames(@This())) |field| m = @max(field.len, m);
            break :blk m;
        };
        var buf:[buf_len]u8 = undefined;
        if (str.len > buf.len) return null;
        for (0..str.len) |i| buf[i] = std.ascii.toLower(str[i]);
        return std.meta.stringToEnum(@This(), buf[0..str.len]);
    }
};
var level:Level = .normal;

var io:std.Io = undefined;
var alloc:std.mem.Allocator = undefined;

pub fn main(init:std.process.Init) !u8 {
    io = init.io;
    alloc = init.gpa;
    var reader_buf:[1024]u8 = undefined;
    outer: while (true) : ({
        try io.sleep(.fromSeconds(5), .real);
    }) {
        var new_status:?Status = status;
        var new_level:Level = level;
        var new_capacity:u8 = 0;
        defer {
            status = new_status;
            level = new_level;
            capacity = new_capacity;
            std.log.debug("{d}% | {t} | {?t}",.{capacity, level,status});
        }
        const info = blk: {
            var file = try std.Io.Dir.cwd().openFile(
                io, bat_uevent, .{ .mode = .read_only }
            );
            defer file.close(io);
            var reader = file.reader(io, &reader_buf);
            break :blk try reader.interface.allocRemaining(alloc, .unlimited);
        };
        defer alloc.free(info);
        var itr = std.mem.tokenizeScalar(u8, info, '\n');
        while (itr.next()) |line| {
            const key, const value = std.mem.cutScalar(u8, line, '=').?;
            if (std.mem.eql(u8, key, "DEVTYPE")) continue;
            const field_name = std.mem.cut(u8, key, "POWER_SUPPLY_").?[1];
            const KnownFields = enum {
                NAME,
                STATUS,
                PRESENT,
                TECHNOLOGY,
                CYCLE_COUNT,
                VOLTAGE_MIN_DESIGN,
                VOLTAGE_NOW,
                POWER_NOW,
                ENERGY_FULL_DESIGN,
                ENERGY_FULL,
                ENERGY_NOW,
                CAPACITY,
                CAPACITY_LEVEL,
                TYPE,
                MODEL_NAME,
                MANUFACTURER,
                SERIAL_NUMBER,
            };
            const field = std.meta.stringToEnum(KnownFields, field_name) orelse {
                std.log.warn(
                    "unknown field (in {s}): |{s}|=|{s}|",
                    .{ bat_uevent, field_name, value }
                );
                continue;
            };
            switch (field) {
                .TYPE => {
                    if (!std.mem.eql(u8, value, "Battery")) {
                        std.log.warn("unknown battery type: |{s}|", .{value});
                        continue;
                    }
                },
                .STATUS => {
                    new_status = Status.fromStr(value) orelse {
                        std.log.warn("unknown battery status: |{s}|", .{value});
                        continue;
                    };
                },
                .PRESENT => {
                    if (!std.mem.eql(u8, value, "1")) {
                        std.log.err("battery not present", .{});
                        break :outer;
                    }
                },
                .CAPACITY => new_capacity = try std.fmt.parseInt(u8, value, 0),
                .CAPACITY_LEVEL => new_level = Level.fromStr(value) orelse {
                    std.log.warn("unknown capacity level: |{s}|", .{value});
                    continue;
                },
                else => continue,
            }
        }
        if (status == null) continue :outer; //ignore initial loop

        var buf:[100]u8 = undefined;
        if (new_status) |s| if (status.? != s) {
            const summary = try std.fmt.bufPrint(
                buf[buf.len/2..], "at {d}% ({t})", .{new_capacity, new_level}
            );
            const body = try std.fmt.bufPrint(
                buf[0..buf.len/2], "battery {t}", .{s}
            );
            try exec(&.{
                    "notify-send",
                    "--urgency=critical",
                    "--category=system",
                    "--app-name=battery",
                    summary,
                    body
            });
            continue;
        };
        if (level != new_level) {
            const body = try std.fmt.bufPrint(
                buf[0..buf.len/2], "{t} battery", .{new_level}
            );
            const summary = try std.fmt.bufPrint(
                buf[buf.len/2..], "at {d}% ({?t})", .{new_capacity, new_status}
            );
            try exec(&.{
                "notify-send",
                "--urgency=critical",
                "--category=system",
                "--app-name=battery",
                summary,
                body,
            });
            continue;
        }
        if (new_capacity != capacity) {
            if (capacity == 0) continue;
            const low = new_capacity <= battery_low;
            const at_threshold = (battery_low -| new_capacity) % percent_threshold == 0;
            if (!low or !at_threshold) continue;
            const summary = try std.fmt.bufPrint(
                buf[0..buf.len/2], "battery: {d}%", .{new_capacity}
            );
            try exec(&.{
                "notify-send",
                "--urgency=critical",
                "--category=system",
                "--app-name=battery",
                summary,
                "low battery",
            });
            continue;
        }

    }
    return 0;
}

fn exec(args:[]const []const u8) !void {
    const junk = try std.process.run(alloc, io, .{
        .argv = args,
    });
    alloc.free(junk.stdout);
    alloc.free(junk.stderr);
}
