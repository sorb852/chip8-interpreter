const std = @import("std");
const rl = @import("raylib");

const ziggy = @import("ziggy");

pub fn main(init: std.process.Init) !void {
    _ = init; // wtf i dont need it now?
    // const arena: std.mem.Allocator = init.arena.allocator();
    const scale = 16;
    const screenWidth = 64 * scale;
    const screenHeight = 32 * scale;

    rl.initWindow(screenWidth, screenHeight, "chip8 emulator");
    defer rl.closeWindow(); // js close as it ends lol

    rl.setTargetFPS(60);

    var prng: std.Random.DefaultPrng = .init(0);

    const chip8: ziggy.Chip8VM = .{ .rand = prng.random() };

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing(); // ok nvm this is cool asf
        rl.clearBackground(.black);

        var x: u6 = 0;
        var y: u6 = 0;
        while (y < 32) : (y += 1) {
            while (x < 64) : (x += 1) {
                if (x == 63) break;
                if (chip8.display[y] & (@as(u64, 1) << (63 - x)) == 1) rl.drawRectangle(x * scale, y * scale, scale, scale, .white);
            }
        }
    }
}
