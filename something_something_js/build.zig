const std = @import("std");

pub fn build(b: *std.Build) void {
    const bin = b.addExecutable(.{
        .name = "something_something_js",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.graph.host,
            .link_libc = true,
        }),
    });

    b.installArtifact(bin);
    bin.addIncludePath(b.path("include"));
    bin.addLibraryPath(b.path("include"));
    bin.addObjectFile(b.path("include/libmujs.a"));
    //include/mujs-1.3.8/build/release/libmujs.a
    for ([_][]const u8 {
        //"mujs", "readline"
    }) |header| bin.root_module.linkSystemLibrary(header, .{});

    const run_bin = b.addRunArtifact(bin);
    if (b.args) |args| {
        run_bin.addArgs(args);
    }
    const run_step = b.step("run", "execute the program");
    run_step.dependOn(&run_bin.step);
}
