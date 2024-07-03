const std = @import("std");

const Dependency = struct {
    name: []const u8,
    module: *std.Build.Module,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Tree-Sitter Library Dependency
    // This builds the tree-sitter library from source
    // We'll require the treez module to be linked to this library below
    const ts = b.dependency("tree-sitter", .{ .optimize = optimize, .target = target });
    const ts_lib = ts.artifact("tree-sitter");
    b.installArtifact(ts_lib);

    // Create the 'treez' module to be exported and used downstream
    // It should contain all of the transitive dependencies required for its use
    // This means downstream users won't need to link against tree-stter themselves
    const treez = b.addModule("treez", .{
        .root_source_file = .{ .path = "treez.zig" },
        .target = target,
        .optimize = optimize,
    });
    treez.linkLibrary(ts_lib);
    const treez_dep = Dependency{ .name = "treez", .module = treez };

    // Example

    const exe = b.addExecutable(.{
        .name = "treez-example",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "example/example.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();

    // Give the executable access to the 'treez' module
    // This includes the transitive dependency on libtree-sitter
    exe.root_module.addImport(treez_dep.name, treez_dep.module);

    // Option one: Defaults to shared-library linking
    // Uses all default options
    // exe.linkSystemLibrary("tree-sitter-zig");
    // Option two: Specify static linking preferred
    exe.linkSystemLibrary2("tree-sitter-zig", .{ .preferred_link_mode = .static });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("example", "Run the example");
    run_step.dependOn(&run_cmd.step);
}
