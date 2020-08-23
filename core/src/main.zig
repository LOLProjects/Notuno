const std = @import("std");
const ModLoader = @import("mod-loader.zig");
usingnamespace @import("cards.zig");

const allocator = std.heap.page_allocator;

pub fn main() !void {
    var cards_reg = try ModLoader.loadGame(allocator, "mods/test.txt");
    defer ModLoader.deinitCardsRegister(&cards_reg);

    var card_it = cards_reg.iterator();
    while (card_it.next()) |c| {
        std.debug.print("{} : {}\n", .{ c.key, c.value.name });
    }
}
