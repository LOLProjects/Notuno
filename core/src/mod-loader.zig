//!This module contains the functions required to load a set of card-mods from a rules file

const std = @import("std");
usingnamespace @import("cards.zig");

///Load a set if card mods (cards register) from a rules file
///Allocator is just for internal logic, nothing is allocated at the end of the function
///The resulting cards register may be deinit with deinitCardsRegister() from module cards.zig
pub fn loadGame(allocator: *std.mem.Allocator, rules_file_path: []const u8) !CardsRegister {
    var ret = CardsRegister.init(allocator);
    errdefer deinitCardsRegister(&ret);

    //Get full path of rules file
    var real_path = try std.fs.realpathAlloc(allocator, rules_file_path);
    defer allocator.free(real_path);

    //Load the file
    var file = try std.fs.openFileAbsolute(real_path, .{});
    defer file.close();

    //File contents into buffer
    var buffer: []u8 = undefined;
    {
        var buf = try file.readAllAlloc(allocator, (try file.stat()).size, std.math.maxInt(usize));
        defer allocator.free(buf);

        //Replace CRLF with LF
        var buf_len = std.mem.replacementSize(u8, buf, "\x0D\n", "\n");
        buffer = try allocator.alloc(u8, buf_len);

        _ = std.mem.replace(u8, buf, "\x0D\n", "\n", buffer);
    }
    defer allocator.free(buffer);

    var lines = std.mem.tokenize(buffer, "\n");

    while (lines.next()) |line| {
        //Get full path of dll
        var dll_path = try std.fs.realpathAlloc(allocator, line);
        defer allocator.free(dll_path);

        var card = try loadCard(dll_path);

        //Add card to register
        if (!ret.contains(card.name)) {
            try ret.put(card.name, card);
        } else {
            return error.DuplicateCard;
        }
    }

    return ret;
}

///Deinits a CardsRegister. To be deferred after a loadGame() (mod-loader.zig)
pub fn deinitCardsRegister(cr: *CardsRegister) void {
    defer cr.deinit();

    var card_it = cr.iterator();
    while (card_it.next()) |c| {
        c.value.dll.close();
    }
}

fn loadCard(dll_path: []const u8) !CardType {
    var ret: CardType = undefined;

    ret.dll = try std.DynLib.open(dll_path);
    errdefer ret.dll.close();

    {
        var name_maybe = ret.dll.lookup(fn () [*:0]const u8, "getName");
        if (name_maybe) |getName| {
            var name = getName();
            ret.name.ptr = name;
            ret.name.len = std.mem.lenZ(name);
        } else return error.DllMissingData;
    }

    return ret;
}
