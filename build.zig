const std = @import("std");

pub fn build(b: *std.Build) void {
    // Base configurations
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Raylib
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");
    // const raygui = raylib_dep.module("raygui"); // Currently not needed, maybe never will
    const raylib_artifact = raylib_dep.artifact("raylib");

    // Base executable
    const create_options = std.Build.Module.CreateOptions{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "raylib", .module = raylib },
        },
    };
    const exe = b.addExecutable(.{
        .name = "chopped",
        .root_module = b.createModule(create_options),
    });
    exe.root_module.linkLibrary(raylib_artifact);
    exe.use_lld = true;
    exe.use_llvm = true;

    // exe.root_module.addImport("raygui", raygui);
    b.installArtifact(exe);

    // Running
    const run_exe = b.addRunArtifact(exe);
    if (b.args) |args|
        run_exe.addArgs(args);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);

    // Unit tests
    const test_step = b.step("test", "Run unit tests");
    const unit_tests = b.addTest(.{
        .root_module = b.createModule(create_options),
    });
    unit_tests.root_module.linkLibrary(raylib_artifact);
    unit_tests.use_lld = true;
    unit_tests.use_llvm = true;

    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);
}
