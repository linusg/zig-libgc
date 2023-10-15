const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libgc = b.dependency("libgc", .{
        .target = target,
        .optimize = optimize,
    });

    // lib for zig
    const lib = b.addStaticLibrary(.{
        .name = "gc",
        .root_source_file = .{ .path = "src/gc.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibrary(libgc.artifact("gc"));
    lib.installLibraryHeaders(libgc.artifact("gc"));
    {
        var main_tests = b.addTest(.{
            .root_source_file = .{ .path = "src/gc.zig" },
            .target = target,
            .optimize = optimize,
        });
        main_tests.linkLibrary(lib);

        const test_step = b.step("test", "Run library tests");
        test_step.dependOn(&main_tests.step);

        b.default_step.dependOn(&lib.step);
        b.installArtifact(lib);
    }

    const module = b.addModule("gc", .{
        .source_file = .{ .path = "src/gc.zig" },
    });

    // example app
    const exe = b.addExecutable(.{
        .name = "example",
        .root_source_file = .{ .path = "example/basic.zig" },
        .target = target,
        .optimize = optimize,
    });
    {
        exe.linkLibrary(lib);
        exe.addModule("gc", module);
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run_example", "run example");
        run_step.dependOn(&run_cmd.step);
    }
}
