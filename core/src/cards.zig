//!This module contains all cards related types: Card (instance), CardType (singleton) and CardsRegister

const std = @import("std");

///A card is an instance of a card. It holds a pointer to a card type (to get behavior and rules)
///It also has an u32 for storing type dependant metadata (such as color or number or both)
pub const Card = struct {
    meta: u32, card_type: *CardType
};

///CardType holds data and function pointers for info about a card type, along with an open dll
///It is meant to be in a cards registers, and not to be instanciated for each card in the game
///An actual card instance will point to a card type
pub const CardType = struct {
    dll: std.DynLib, name: [:0]const u8
};

///A cards register contains Card Types with their names as keys
///Loading a game loadGame() in module mod-loader.zig will give a CardsRegister
pub const CardsRegister = std.hash_map.StringHashMap(CardType);
