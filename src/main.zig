const std = @import("std");
const rl = @import("raylib");

const ziggy = @import("ziggy");

const scale = 16;
const screenWidth = 64 * scale;
const screenHeight = 32 * scale;

/// Prints the help information onto stderr
/// TODO: Move to stdout
fn print_help(executable: *[]const u8) void {
    std.debug.print("Usage: {s} [OPTIONS] <FILE>\n", .{executable});
    std.debug.print("\n", .{});
    std.debug.print("Arguments:\n", .{});
    std.debug.print("\t<FILE>: The chip8 file to be executed.\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("Options:\n", .{});
    std.debug.print("\t--help, -h:                          Display help information.\n", .{});
    std.debug.print("\t--target-tickrate <RATE>, -t <RATE>: Change the tick rate of the emulator.\n", .{});
}

pub fn main(init: std.process.Init) !void {
    // const arena: std.mem.Allocator = init.arena.allocator();

    var rom_path: ?[:0]const u8 = null;
    // like i defeinelty wont see you running 10^9 fps. but whataver mane, up to you
    // mane what the fuck why is the argument for rl.setTargetFPS(i32)
    // i get this disgusting fucking number
    var target_tickrate: i32 = 480;

    var args = init.minimal.args.iterate();
    const executable = std.fs.path.stem(args.next().?);
    while (args.next()) |arg| {
        if (std.ascii.eqlIgnoreCase(arg, "--help") or std.ascii.eqlIgnoreCase(arg, "-h")) {
            print_help(&executable);
            std.process.exit(0);
        }

        if (std.ascii.eqlIgnoreCase(arg, "--target-tickrate") or std.ascii.eqlIgnoreCase(arg, "-t")) {
            if (args.next()) |valuestr| {
                target_tickrate = std.fmt.parseInt(@TypeOf(target_tickrate), valuestr, 10) catch |err|
                    switch (err) {
                        error.Overflow => {
                            std.debug.print("error: Target tick rate must be a 32 bit integer.\n", .{});
                            std.process.exit(1);
                        },
                        error.InvalidCharacter => {
                            std.debug.print("error: Invalid tick rate.\n", .{});
                            std.process.exit(1);
                        },
                    };
                continue;
            } else {
                std.debug.print("error: No tick rate found for option.\n", .{});
                std.process.exit(1);
            }
        }

        if (rom_path) |_| {
            std.debug.print("error: Only one argument for file should be shown\n", .{});
            std.process.exit(1);
        } else {
            rom_path = arg;
        }
    }

    if (rom_path) |_| {} else {
        std.debug.print("error: No rom given in arguments.\n", .{});
        std.process.exit(1);
    }

    // Initialize chip8
    var prng: std.Random.DefaultPrng = .init(0);
    var chip8: ziggy.Chip8VM = .{ .rand = prng.random() };
    chip8.init_sprites();

    // Initialize the rom
    var buf: [4096 - 512]u8 = undefined;
    const rom_path_type = std.fs.path.parsePath(rom_path);
    const rom = (if (rom_path_type.kind == .absolute)
        std.Io.Dir.openFileAbsolute(init.io, rom_path.?, .{ .allow_directory = false })
    else
        std.Io.Dir.cwd().openFile(init.io, rom_path.?, .{ .allow_directory = false })) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("error: Rom not found.\n", .{});
            std.process.exit(1);
        },
        error.IsDir => {
            std.debug.print("error: Given rom path is not a file.\n", .{});
            std.process.exit(1);
        },
        else => {
            std.debug.print("error: failed to open rom, {}.\n", .{err});
            std.process.exit(1);
        }
    };
    var rom_reader = rom.reader(init.io, &buf);
    try chip8.init_rom(&rom_reader.interface);
    rom.close(init.io);

    rl.initWindow(screenWidth, screenHeight, "chip8 emulator");
    defer rl.closeWindow(); // js close as it ends lol

    rl.setTargetFPS(target_tickrate);

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
