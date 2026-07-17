const std = @import("std");
const Io = std.Io;

const ziggy = @import("ziggy");

/// Applies the main rule of collatz conjecture to number `a`.
fn apply_rule(a: u64) u64 {
    return if (a % 2 == 0) (a / 2) else (3 * a + 1);
}

/// Creates the sequence of numbers generated when the starting number is `start`
fn create_chain(list: *std.ArrayList(u64), allocator: std.mem.Allocator, start: u64) !void {
    try list.append(allocator, start);
    while (list.getLast() > 1) {
        // no i am not changing this
        // idiot admires complexity
        // and wouldnt you know, long ass one liner that is slow
        try list.append(allocator, apply_rule(list.getLast()));
    }
}

/// Get's the first argument and takes it as the value for `n`
fn get_n(args_raw: *const std.process.Args, allocator: std.mem.Allocator) !u64 {
    const args = try args_raw.toSlice(allocator);
    return try std.fmt.parseInt(u64, args[1], 10); // yeah im gonan be a lazy bum and do this
}

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
