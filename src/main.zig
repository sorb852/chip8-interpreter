const std = @import("std");

const ziggy = @import("ziggy");

/// Main Chip-8 manager
const Chip8VM = struct {
    /// starts main game memory at 512
    memory: [4096]u8 = [0]**4096,
    V: [16]u8 = [0]**16,
    I: u16,
    DT: u8 = 0,
    ST: u8 = 0,
    PC: u16,
    SP: u8,
    stack: [16]u16,
    keyboard: u16,
    display: u64[32],

    /// Clear screen
    fn CLS(self: *Chip8VM) void {
        for (self.display) |row| {
            row = 0;
        }
    }
    /// Return from subroutine
    fn RET(self: *Chip8VM) void {
        self.PC = self.stack[self.SP];
        self.SP -= 1;
    }
    /// Jump to address
    fn JP(self: *Chip8VM, addr: u16) void {
        self.PC = addr;
    }
    /// Call a subroutine
    fn CALL(self: *Chip8VM, addr: u16) void {
        self.SP += 1;
        self.stack[self.SP] = self.PC;
        self.PC = addr;
    }
    /// Skip next instruction if *Vx* == byte
    fn SE(self: *Chip8VM, x: u8, byte: u8) void {
        if (self.V[x] == byte)
            self.PC += 2;
    }
    /// Skip next instruction if *Vx* != byte
    fn SNE(self: *Chip8VM, x: u8, byte: u8) void {
        if (self.V[x] != byte)
            self.PC += 2;
    }
    /// Skip next instruction if *Vx* == *Vy*
    fn SEV(self: *Chip8VM, x: u8, y: u8) void {
        if (self.V[x] == self.V[y])
            self.PC += 2;
    }
    /// Sets a value to register *Vx*
    fn LD(self: *Chip8VM, x: u8, byte: u8) void {
        self.V[x] = byte;
    }
    /// Increment register *Vx* by a value
    fn ADD(self: *Chip8VM, x: u8, byte: u8) void {
        self.V[x] +%= byte;
    }
    /// Sets *Vx* to *Vy*
    fn LDV(self: *Chip8VM, x: u8, y: u8) void {
        self.V[x] = self.V[y];
    }
    /// Sets *Vx* to *Vx* | *Vy*
    fn OR(self: *Chip8VM, x: u8, y: u8) void {
        self.V[x] |= self.V[y];
    }
    /// Sets *Vx* to *Vx* & *Vy*
    fn AND(self: *Chip8VM, x: u8, y: u8) void {
        self.V[x] &= self.V[y];
    }
    /// Sets *Vx* to *Vx* ^ *Vy*
    fn XOR(self: *Chip8VM, x: u8, y: u8) void {
        self.V[x] ^= self.V[y];
    }
    /// Sets *Vx* to *Vx* + *Vy* and *VF* as the carry out
    fn ADDV(self: *Chip8VM, x: u8, y: u8) void {
        const added = self.V[x] +% self.V[y];
        self.V[x] = added;
        self.V[0xF] = if (added < self.V[x]) 1 else 0;
    }
    /// Sets *Vx* to *Vx* - *Vy* and set *VF* to `!*borrow*`
    fn SUB(self: *Chip8VM, x: u8, y: u8) void {
        const added = u16(self.V[x]) + u16(self.V[y]);
        self.V[x] = u8(added % 256);
        self.V[0xF] = if (added < self.V[x]) 1 else 0; // i got a proof for this and everything (i know, basic algebra BBUT it IS algebra. we can js ignore the easy part)
    }
    fn TEMPLATE(self: *Chip8VM) void {}
};

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const io = init.io;

    // stdout boilerplate
    var stdout_buffer: [512]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
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
