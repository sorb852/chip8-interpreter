const std = @import("std");
const Io = std.Io;

const ziggy = @import("ziggy");

/// Main Chip-8 manager
const Chip8VM = struct {
    /// starts main game memory at 512
    memory: [4096]u8 = [0] ** 4096,
    V: [16]u8 = [0] ** 16,
    I: u16,
    DT: u8 = 0,
    ST: u8 = 0,
    PC: u16,
    SP: u8,
    stack: [16]u16,
    keyboard: u16,
};

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const io = init.io;

    // stdout boilerplate
    var stdout_buffer: [512]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    const n: u64 = try get_n(&init.minimal.args, arena);
    var chain: std.ArrayList(u64) = .empty;
    try create_chain(&chain, arena, n);

    // look im sorry if your stdout is somehow bbroken
    // but i just could NOT care less
    for (chain.items) |part| {
        stdout.print("{d} ", .{part}) catch {};
    }
    stdout.print("\n", .{}) catch {};
    try stdout.flush();
}
