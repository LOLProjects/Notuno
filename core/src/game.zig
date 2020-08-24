const Allocator = @import("std").mem.Allocator;
usingnamespace @import("cards.zig");

/// Stores all information needed for a game, such as all the players,
/// the current player's turn, and piles such as the draw pile
pub const Game = struct {
    const Self = @This();
    players: []Player,
    current_player_index: u8,
    draw_pile: DrawPile,

    pub fn init(alloc: *Allocator) !Self {
        var players = try alloc.alloc(Player, 2);
        for (players) |*player| {
            player.* = Player.init();
        }
        return Self{
            .players = players,
            .current_player_index = 0,
            .draw_pile = try DrawPile.init(alloc),
        };
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
};

/// Each player only has a hand for now.
pub const Player = struct {
    const Self = @This();
    hand: Hand,

    pub fn init() Self {
        return Self{
            .hand = Hand.init(),
        };
    }
};

/// The draw pile is the pile that players will draw from when the game instructs so.
pub const DrawPile = struct {
    const Self = @This();
    cards: []Card,

    pub fn init(alloc: *Allocator) !Self {
        var cards = try alloc.alloc(Card, 20);
        return Self{
            .cards = cards,
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

    pub fn init() Self {
        //var card_type = CardType{};
        return Self{
            .cards = [_]?Card{Card{ .meta = 0, .card_type = undefined }} ** 7,
        };
    }
};
