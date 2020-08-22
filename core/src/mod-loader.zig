//!This module contains the functions required to loading a set of card-mods from a rules file

const std = @import("std");
usingnamespace @import("cards.zig");

///Load a set if card mods (cards register) from a rules file
///Allocator is just for internal logic, nothing is allocated at the end of the function
///The resulting cards register may be deinit with deinitCardsRegister() from module cards.zig
pub fn loadGame(allocator: *std.mem.Allocator, rules_file_path: []const u8) !CardsRegister {
    var ret = CardsRegister.init();
    errdefer deinitCardsRegister(ret);

    //Get full path of rules file
    var real_path = std.fs.realpathAlloc(allocator, rules_file_path);
    defer allocator.free(real_path);

    //Load the file
    var rules_file = try std.fs.openFileAbsolute(real_path, .{});

    if (rules_file) |file| {
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
            var card = try loadCard(line);

            //Todo
            //check name
            //put card mod in cards register
        }

    } else return error.FileError;

    return ret;
}

fn loadCard(dll_path: []const u8) !Card {

}