const std = @import("std");
const table = @import("table.zig");
const Sniffer = @import("sniffer.zig").Sniffer;

const the_list = table.the_list;

const stdout = &@constCast(&std.fs.File.stdout().writer(&.{})).interface;
const stderr = &@constCast(&std.fs.File.stderr().writer(&.{})).interface;

pub fn main() !void {
    var args = std.process.args();
    _ = args.skip(); //skip the path to the binary
    
    //holds the file name for the file to check (set by args)
    var filename:?[]const u8 = null;

    // TODO: change this to properly evaluate args
    //  (instead of just treating the last arg as the filename)
    while (args.next()) |a| filename = a;

    //the main allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    var alloc = gpa.allocator();

    //byte slice used for the input 
    var input:?[]const u8 = null;
    defer if (input) |str| alloc.free(str); //only frees if not null

    //if the filename isn't null (meaning set by arg) 
    if (filename) |name| {
        const stat = std.fs.cwd().statFile(name) catch |e| {
            try stderr.print("couldn't stat file: {t}\n", .{e});
            std.process.exit(1);
        };
        if (stat.kind != .file) {
            try stderr.print("{s} does not appear to be a file\n", .{name});
            std.process.exit(1);
        }
        //attempt to open the file
        //   TODO: handle errors here in a 'catch' block
        var file = std.fs.cwd().openFile(name, .{
            .lock = .exclusive,
        }) catch |e| {
            try stderr.print("couldn't open file: {t}\n", .{e});
            std.process.exit(1);
        };
        //a reader for the file
        var reader = &@constCast(&file.reader(&.{})).interface;
        //just read the whole thing into memory
        input = try reader.allocRemaining(alloc, .unlimited);
    } else {
        //no filename provided (no args), print to stderr and exit
        try stderr.print("no filename provided\n", .{});
        std.process.exit(1);
    }
    
    const home = std.process.getEnvVarOwned(alloc, "HOME") catch {
        try stderr.print("either unsupported (non-UNIX) system or $HOME not set", .{});
        std.process.exit(1);
    };
    defer alloc.free(home);
    const path:[]const []const u8 = &[_][]const u8 { home, ".config", "sniffer.zon" };
    const dataset_path = try std.fs.path.join(alloc, path);
    defer alloc.free(dataset_path);
    var dataset_file = try std.fs.openFileAbsolute(dataset_path, .{
        .lock = .exclusive,
    });
    defer dataset_file.close();

    var dataset_reader = &@constCast(&dataset_file.reader(&.{})).interface;
    const dataset_string_R = try dataset_reader.allocRemaining(alloc, .unlimited);
    defer alloc.free(dataset_string_R);
    //add the zig-required C sentenial
    const dataset_string:[:0]const u8 = try alloc.dupeZ(u8, dataset_string_R);
    defer alloc.free(dataset_string);
    
    const dataset_zon = std.zon.parse.fromSlice(
        []table.Filetype, alloc, dataset_string, null, .{}
    ) catch |e| {
        try stderr.print("failed to parse zon dataset: {t}\n", .{e});
        std.process.exit(1);
    };
    defer std.zon.parse.free(alloc, dataset_zon);

    //initialize a sniffer
    //  the '.?' assumes non-null
    var sniffer = Sniffer.init(@constCast(input.?), filename.?, dataset_zon); 
    
    //try to find a match using everything in the dataset 
    const match = sniffer.chk_all() catch {
        try stdout.print("couldn't match data\n", .{});
        std.process.exit(0);
    };

    //print the result (multi-line string)
    try stdout.print(
        \\
        \\match found.
        \\type: {s}
        \\file extension: {s}
        \\description: {s}
        \\
    , .{
        match.type,
        match.ext orelse "[none]", //if no extension, print "[none]" instead of panicing 
        match.desc,
    });
}
