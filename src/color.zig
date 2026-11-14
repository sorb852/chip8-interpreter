const std = @import("std");
const rl = @import("raylib");

pub const HexConversionError = error{InvalidScheme} || std.fmt.ParseIntError;

/// Converts a hex string to a `raylib.Color`
pub fn color_from_hex(s: []const u8) HexConversionError!rl.Color {
    if (s.len != 7 or s[0] != '#') return error.InvalidScheme;
    const parsed = try std.fmt.parseInt(u24, s[1..7], 16);
    return .{
        .r = @truncate((parsed & 0xFF0000) >> 16),
        .g = @truncate((parsed & 0x00FF00) >> 8),
        .b = @truncate((parsed & 0x0000FF) >> 0),
        .a = 255,
    };
}

pub fn color_to_hex(c: rl.Color) [7]u8 {
    var buf: [7]u8 = undefined;
    if (std.fmt.bufPrint(&buf, "#{x:0>2}{x:0>2}{x:0>2}", .{ c.r, c.g, c.b }) == error.NoSpaceLeft)
        unreachable;
    return buf;
}

test "successful color from hex" {
    const expectEqual = std.testing.expectEqual;

    try expectEqual(rl.Color.init(0xFF, 0x00, 0x00, 0xFF), try color_from_hex("#FF0000"));
    try expectEqual(rl.Color.init(0x00, 0xFF, 0x00, 0xFF), try color_from_hex("#00Ff00"));
    try expectEqual(rl.Color.init(0x00, 0x00, 0xFF, 0xFF), try color_from_hex("#0000fF"));

    try expectEqual(rl.Color.init(0xFF, 0xFF, 0xFF, 0xFF), try color_from_hex("#FfFFfF"));
    try expectEqual(rl.Color.init(0x00, 0x00, 0x00, 0xFF), try color_from_hex("#000000"));

    try expectEqual(rl.Color.init(0xF9, 0xA8, 0x24, 0xFF), try color_from_hex("#f9a824"));
    try expectEqual(rl.Color.init(0xD3, 0x20, 0xD2, 0xFF), try color_from_hex("#d320D2"));
}

test "failed colors from hex" {
    const expectError = std.testing.expectError;

    try expectError(error.InvalidScheme, color_from_hex("0xff00ff"));
    try expectError(error.InvalidScheme, color_from_hex("#abcdefg"));
    try expectError(error.InvalidScheme, color_from_hex(".hello world!"));
    try expectError(error.InvalidScheme, color_from_hex("zig for the win"));
    try expectError(error.InvalidScheme, color_from_hex("##ff0000"));
    try expectError(error.InvalidCharacter, color_from_hex("#fg0000"));
    try expectError(error.InvalidCharacter, color_from_hex("#0G000f"));
}

test "color to hex" {
    const expectEqualStrings = std.testing.expectEqualStrings;

    try expectEqualStrings("#ff0000", &color_to_hex(.init(0xFF, 0x00, 0x00, 0xFF)));
    try expectEqualStrings("#00ff00", &color_to_hex(.init(0x00, 0xFF, 0x00, 0xFF)));
    try expectEqualStrings("#0000ff", &color_to_hex(.init(0x00, 0x00, 0xFF, 0xFF)));

    try expectEqualStrings("#ffffff", &color_to_hex(.init(0xFF, 0xFF, 0xFF, 0xFF)));
    try expectEqualStrings("#000000", &color_to_hex(.init(0x00, 0x00, 0x00, 0xFF)));

    try expectEqualStrings("#f9a824", &color_to_hex(.init(0xF9, 0xA8, 0x24, 0xFF)));
    try expectEqualStrings("#d320d2", &color_to_hex(.init(0xD3, 0x20, 0xD2, 0xFF)));
}
