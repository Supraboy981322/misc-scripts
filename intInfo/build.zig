const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const bin = b.addExecutable(.{
        .name = "intInfo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(bin);
    const run_bin = b.addRunArtifact(bin);
    if (b.args) |args| run_bin.addArgs(args);
    const run_step = b.step("run", "run the program");
    run_step.dependOn(&run_bin.step);
}
