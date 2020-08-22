const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const files = [_][]const u8{
        "basic-number"
    };

    inline for (files) |file| {
        const dll = b.addSharedLibrary(file, "cards/" ++ file ++ ".zig", .{.minor = 0, .major = 0});
        dll.setTarget(target);
        dll.setBuildMode(mode);
        dll.install();
    }
}