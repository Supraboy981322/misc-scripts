const std = @import("std");

pub fn build(b: *std.Build) void {
    const bin = b.addExecutable(.{
        .name = "compression_defeater_2000",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.graph.host,
            .link_libc = true,
        }),
    });

    b.installArtifact(bin);

    const run_bin = b.addRunArtifact(bin);
    if (b.args) |args| {
        run_bin.addArgs(args);
    }
    const run_step = b.step("run", "run the program");
    run_step.dependOn(&run_bin.step);
}
