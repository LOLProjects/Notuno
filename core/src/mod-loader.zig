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

    try checkDependencies(ret);

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

const GetDepsFnType = fn (*u8) ?[*][]const u8;

///Iterates on a cards register to check if all the cards mods have the cards they depend on
fn checkDependencies(cr: CardsRegister) !void {
    var card_it = cr.iterator();
    while (card_it.next()) |c| {
        //Get the dependencies through a dll function, or continue
        var getDependencies = c.value.dll.lookup(GetDepsFnType, "getDependencies") orelse continue;

        var deps_count: u8 = 0;
        var deps_ptr = getDependencies(&deps_count);

        if (deps_ptr) |dependencies| {
            //Iterate over this card's dependencies
            deps_loop: for (dependencies[0..deps_count]) |dependency| {
                //Iterate over the cards again to see if a card's name matches the needed dependency
                var card_it_2 = cr.iterator();
                while (card_it_2.next()) |c2| {
                    if (std.mem.eql(u8, c2.value.name, dependency))
                        continue :deps_loop;
                }
                
                std.debug.print("Error: Card '{}' has a missing dependency : '{}'.\n", .{c.value.name, dependency});
                return error.MissingDependency;
            }
        } else {    //Returned pointer is null?
            if (deps_count != 0)
                return error.GetDependenciesError;
        }
    }
}

///Loads a single card (mod)
fn loadCard(dll_path: []const u8) !CardType {
    var ret: CardType = undefined;

    ret.dll = try std.DynLib.open(dll_path);
    errdefer ret.dll.close();

    {
        var name_maybe = ret.dll.lookup(fn () [*:0]const u8, "getName");
        if (name_maybe) |getName| {
            ret.name = std.mem.span(getName());
        } else return error.DllMissingData;
    }

    return ret;
}
