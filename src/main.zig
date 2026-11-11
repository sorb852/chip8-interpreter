const std = @import("std");
const rl = @import("raylib");

const ziggy = @import("ziggy");

pub fn main(init: std.process.Init) !void {
    // const arena: std.mem.Allocator = init.arena.allocator();
    const scale = 16;
    const screenWidth = 64 * scale;
    const screenHeight = 32 * scale;

    rl.initWindow(screenWidth, screenHeight, "chip8 emulator");
    defer rl.closeWindow(); // js close as it ends lol

    rl.setTargetFPS(480);

    var prng: std.Random.DefaultPrng = .init(0);

    var chip8: ziggy.Chip8VM = .{ .rand = prng.random() };

    var buf: [4096 - 512]u8 = undefined;
    // const rom = try std.Io.Dir.cwd().openFile(std.Io, "pong.ch8",  .{});
    const rom = try std.Io.Dir.cwd().openFile(init.io, "pong.ch8", .{});
    var romReader = rom.reader(init.io, &buf);
    defer rom.close(init.io);

    chip8.init_sprites();
    try chip8.init_rom(&romReader.interface);

    var since_last_tick: f64 = 0;

    while (!rl.windowShouldClose() and !chip8.finished) {
        since_last_tick += rl.getFrameTime();

        // 1234     123C
        // QWER     456D
        // ASDF ==> 798E
        // ZXCV     A0BF

        chip8.poll_input(0x1, rl.isKeyDown(.one));
        chip8.poll_input(0x2, rl.isKeyDown(.two));
        chip8.poll_input(0x3, rl.isKeyDown(.three));
        chip8.poll_input(0x4, rl.isKeyDown(.four));

        chip8.poll_input(0x4, rl.isKeyDown(.q));
        chip8.poll_input(0x5, rl.isKeyDown(.w));
        chip8.poll_input(0x6, rl.isKeyDown(.e));
        chip8.poll_input(0xD, rl.isKeyDown(.r));

        chip8.poll_input(0x7, rl.isKeyDown(.a));
        chip8.poll_input(0x8, rl.isKeyDown(.s));
        chip8.poll_input(0x9, rl.isKeyDown(.d));
        chip8.poll_input(0xE, rl.isKeyDown(.f));

        chip8.poll_input(0xA, rl.isKeyDown(.z));
        chip8.poll_input(0x0, rl.isKeyDown(.x));
        chip8.poll_input(0xB, rl.isKeyDown(.c));
        chip8.poll_input(0xF, rl.isKeyDown(.v));

        if (since_last_tick >= 1.0 / 60.0) {
            chip8.tick_timers();
            since_last_tick = 0;
        }

        chip8.step();

        rl.beginDrawing();
        defer rl.endDrawing(); // ok nvm this is cool asf

        if (chip8.needs_redraw) {
            rl.clearBackground(.black);
            var y: usize = 0;
            while (y < 32) : (y += 1) {
                var x: usize = 0;
                while (x < 64) : (x += 1) {
                    const mask = @as(u64, 1) << @intCast(63 - x);
                    if ((chip8.display[y] & mask) != 0) rl.drawRectangle(@intCast(x * scale), @intCast(y * scale), scale, scale, .white);
                }
            }
        }
    }
}
