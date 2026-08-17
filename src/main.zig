const std = @import("std");

const ziggy = @import("ziggy");

fn draw_chip8_display(vm: *ziggy.Chip8VM, output: *std.Io.Writer) void {
    for (vm.display) |row| {
        var index: u64 = 1 << 63;
        while (index > 0) : (index <<= 1)
            output.print("{s}", .{if ((row & index) != 0) "█" else " "});
        output.print("\n");
    }
}

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const io = init.io;

    // stdout boilerplate
    var stdout_buffer: [512]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    var chip8 = ziggy.Chip8VM;
    chip8.rand = prng.random();
    // TODO: read

    while (!chip8.finished) {
        // TODO: chip8.poll_input();
        chip8.tick();
        draw_chip8_display(&chip8, &stdout);
    }
}
