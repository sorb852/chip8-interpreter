const std = @import("std");
const rl = @import("raylib");

const ziggy = @import("ziggy");

pub fn main(init: std.process.Init) !void {
    _ = init; // wtf i dont need it now?
    // const arena: std.mem.Allocator = init.arena.allocator();
    const screenWidth = 64;
    const screenHeight = 32;

    rl.initWindow(screenWidth, screenHeight, "chip8 emulator");
    defer rl.closeWindow(); // js close as it ends lol

    rl.setTargetFPS(60);

    // var prng: std.Random.DefaultPrng = .init(blk: {
    //     var seed: u64 = undefined;
    //     try std.posix.getrandom(std.mem.asBytes(&seed));
    //     break :blk seed;
    // });
    //
    // var chip8 = ziggy.Chip8VM;
    // chip8.rand = prng.random();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing(); // ok nvm this is cool asf
        rl.clearBackground(.ray_white);
    }
}
