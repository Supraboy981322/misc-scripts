const std = @import("std");

pub fn build(b: *std.Build) void {
    const do_symlink = b.option(bool, "do_symlink", "create symlinks for binary") orelse false;
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
    if (do_symlink) try doSymlinks(b, bin);
    const run_bin = b.addRunArtifact(bin);
    if (b.args) |args| run_bin.addArgs(args);
    const run_step = b.step("run", "run the program");
    run_step.dependOn(&run_bin.step);
}

fn doSymlinks(b:*std.Build, bin:*std.Build.Step.Compile) !void {
    for ([_][]const u8 {
        "maxInt",
        "minInt",
    }) |sym_name| {
        const cmd = b.addSystemCommand(&.{ "ln", "-s" });
        const bin_path = bin.getEmittedBin();
        cmd.addFileArg(bin_path);
        cmd.addFileArg(bin_path.dirname().path(b, sym_name));
        cmd.step.dependOn(&bin.step);
        b.getInstallStep().dependOn(&cmd.step);
    }
}
