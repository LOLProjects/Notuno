export const name: []const u8  = "basic-4colors-0-9number";

export const dependencies: u8 = 0;
export const depends_on = [dependencies][]const u8{};   //This card doesn't need anything

export fn canBePlaced(top_card_name: [*:0]const u8 , top_card_meta: u32) bool {
    return true;
}

