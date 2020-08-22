const std = @import("std");

const allocator = std.heap.page_allocator;

const CanBePlacedT = fn ([*:0]const u8, u32) bool;

pub fn main() !void {
    const path = try std.fs.realpathAlloc(allocator, "mods/basic-number.dll"); //Made mods folder in core but it's gitignored out as it's only full of dll
    defer allocator.free(path);

    std.debug.print("path: {}\n", .{path});

    var card = try std.DynLib.open(path);    
    defer card.close();

    std.debug.print("dll is open\n", .{});

    var func = card.lookup(CanBePlacedT, "canBePlaced");

    if (func) |canBePlaced| {
        var r = canBePlaced("idk", 0);
        std.debug.print("expect true: {}\n", .{r});
    } else
        @panic("card doesn't have canBePlaced() function");
}
