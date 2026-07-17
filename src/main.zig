const std = @import("std");
const Io = std.Io;

const ziggy = @import("ziggy");

fn apply_rule(a: u64) u64 {
    return if (a % 2 == 0) (a / 2) else (3 * a + 1);
}

pub fn main(init: std.process.Init) !void {
    // okay so supposedly our main allocator
    const arena: std.mem.Allocator = init.arena.allocator();

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    var stdout_buffer: [512]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    const args = try init.minimal.args.toSlice(arena);
    const n = try std.fmt.parseInt(u64, args[1], 10); // yeah im gonan be a lazy bum and do this

    var chain: std.ArrayList(u64) = .empty;
    (try chain.addOne(arena)).* = n;

    while (chain.getLast() > 1) {
        const new = apply_rule(chain.getLast());
        (try chain.addOne(arena)).* = new;
    }

    // look im sorry if your stdout is somehow bbroken
    // but i just could NOT care less
    for (chain.items) |part| {
        stdout.print("{d} ", .{part}) catch {};
    }
    stdout.print("\n", .{}) catch {};

    try stdout.flush(); // Don't forget to flush!
}
