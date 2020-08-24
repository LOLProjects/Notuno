const card_name: [*:0]const u8 = "basic-4colors-0-9number";
export fn getName() [*:0]const u8 {
    return card_name;
}

const dependencies: u8 = 0;
const depends_on = [dependencies][]const u8{}; //This card doesn't need anything
export fn getDependencies(dep_count: *u8) ?[*][]const u8 { //It is ok to not have this function, mod_loader will assume theres no dependencies
    dep_count.* = dependencies;

    if (dependencies == 0) {
        return @intToPtr(?[*][]const u8, 0);
    } else {
        return *depends_on[0];
    }
}

export fn canBePlaced(top_card_name: [*:0]allowzero const u8, top_card_meta: u32) bool {
    return true;
}
