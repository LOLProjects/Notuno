const std = @import("std");
const allocator = std.heap.page_allocator;
const ModLoader = @import("mod-loader.zig");
usingnamespace @import("cards.zig");
usingnamespace @import("game.zig");
const CanBePlacedT = fn ([*:0]allowzero const u8, u32) bool;

pub fn main() !void {
    const stdout = std.io.getStdOut().outStream();
    const stdin = std.io.getStdIn();
    var buffer: [20]u8 = undefined;
    var running: bool = true;

    try stdout.print("Loading mods\n", .{});
    var cards_reg = try ModLoader.loadGame(allocator, "mods/test.txt");
    defer ModLoader.deinitCardsRegister(&cards_reg);
    var card_it = cards_reg.iterator();
    while (card_it.next()) |c| {
        std.debug.print("Loaded card: {}\n", .{ c.value.name });
    }

    try stdout.print("Game starting with 2 players and stuff\n", .{});
    var game: Game = try Game.init(allocator, cards_reg);
    defer game.free(allocator);

    while (running) {
        try stdout.print("It is player {}'s turn! Your hand is:\n", .{game.current_player_index + 1});
        game.displayHand();
        try stdout.print("Choose a card to play: ", .{});

        const line: ?[]const u8 = getLine(stdin, buffer[0..]) catch |err| {
            switch (err) {
                error.StreamTooLong => try stdout.print("Input was too long!\n", .{}),
                else => {},
            }
            continue;
        };

        if (line) |val| {
            var num: u8 = std.fmt.parseUnsigned(u8, val, 10) catch |err| {
                try stdout.print("Pass a positive number!\n", .{});
                continue;
            };
            num -= 1;

            var player_cards = &game.getCurrentPlayer().hand.cards;

            if (num >= player_cards.len) {
                try stdout.print("Number ({}) is not a card :(\n", .{num + 1});
                continue;
            }

            if (player_cards[num]) |card| {
                player_cards[num] = null;
                _ = game.nextPlayer();
            } else {
                try stdout.print("Number ({}) is not a card :(\n", .{num + 1});
                continue;
            }
        } else {
            return;
        }
    }
}

/// Get next line, excluding \r\n
fn getLine(file: std.fs.File, buffer: []u8) !?[]const u8 {
    var line: ?[]const u8 = try file.reader().readUntilDelimiterOrEof(buffer, '\n');
    if (line) |val| {
        return std.mem.trimRight(u8, val, "\r\n");
    }
    return line;
}

// test "modloader" {
//     var cards_reg = try ModLoader.loadGame(allocator, "mods/test.txt");
//     defer ModLoader.deinitCardsRegister(&cards_reg);

//     var card_it = cards_reg.iterator();
//     while (card_it.next()) |c| {
//         std.debug.print("{} : {}\n", .{ c.key, c.value.name });
//     }
// }
