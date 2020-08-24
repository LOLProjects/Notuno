//! This module contains all the structures used to contain a game state

const std = @import("std");
const Allocator = std.mem.Allocator;
usingnamespace @import("cards.zig");

/// Stores all information needed for a game, such as all the players,
/// the current player's turn, and piles such as the draw pile
pub const Game = struct {
    const Self = @This();
    //rules: RuleSet,
    cards_reg: *const CardsRegister,
    players: []Player,
    current_player_index: u8,
    draw_pile: DrawPile,

    pub fn init(alloc: *Allocator, cards: CardsRegister) !Self {
        var ret = Self{
            .cards_reg = &cards,
            .players = undefined,
            .current_player_index = 0,
            .draw_pile = try DrawPile.init(alloc, &cards),
        };

        ret.players = try alloc.alloc(Player, 2);
        for (ret.players) |*player| {
            player.* = Player.init(&ret);
        }

        return ret;
    }

    pub fn getCurrentPlayer(self: Self) *Player {
        return &self.players[self.current_player_index];
    }

    pub fn free(self: *Self, alloc: *Allocator) void {
        alloc.free(self.players);
        self.draw_pile.free(alloc);
    }

    pub fn nextPlayer(self: *Self) u8 {
        self.current_player_index = @intCast(u8, (self.current_player_index + 1) % self.players.len);
        return self.current_player_index;
    }

    pub fn displayHand(self: Game) void {
        for (self.getCurrentPlayer().hand.cards) |card, i| {
            if (card) |val| {
                //std.debug.print("Card #{} is of type '{}' and has meta 0x{x}.\n", .{i + 1, val.card_type.name, val.meta});
                std.debug.print("Card #{}: {}\n", .{i + 1, val});
            }
        }
    }
};

/// Each player only has a hand for now.
pub const Player = struct {
    const Self = @This();
    hand: Hand,

    pub fn init(game: *Game) Self {
        return Self{
            .hand = Hand.init(game),
        };
    }
};

/// The draw pile is the pile that players will draw from when the game instructs so.
pub const DrawPile = struct {
    const Self = @This();
    cards: []Card,
    card_reg: *const CardsRegister,

    pub fn init(alloc: *Allocator, card_reg: *const CardsRegister) !Self {
        var cards = try alloc.alloc(Card, 20);
        return Self{
            .cards = cards,
            .card_reg = card_reg
        };
    }

    pub fn draw(self: *DrawPile) ?Card {
        //Temporary
        if (!self.card_reg.contains("basic-4colors-0-9number"))
            return null;

        return Card {
            .meta = 0,
            .card_type = &self.card_reg.get("basic-4colors-0-9number").?
        };
    }

    pub fn free(self: *Self, alloc: *Allocator) void {
        alloc.free(self.cards);
    }
};

/// A hand represents the cards that a player is holding.
pub const Hand = struct {
    const Self = @This();
    cards: [7]?Card,

    pub fn init(game: *Game) Self {
        var ret = Self{
            .cards = [_]?Card{null} ** 7,
        };

        for (ret.cards) |*card| {
            card.* = game.draw_pile.draw();
        }

        return ret;
    }
};
