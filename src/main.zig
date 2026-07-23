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
        self.V[0xF] = if (added < self.V[x]) 1 else 0;
        self.V[x] = added;
    }
    /// Sets *Vx* to *Vx* - *Vy* and set *VF* to `!*borrow*`
    fn SUB(self: *Chip8VM, x: u8, y: u8) void {
        self.V[0xF] = if (self.V[x] > self.V[y]) 1 else 0;
        self.V[x] -%= self.V[y];
    }
    /// Bitwise shift *Vx* left by one and set *VF* to 1 if least significant bit is 1
    fn SHR(self: *Chip8VM, x: u8) void {
        self.V[0xF] = self.V[x] & 1;
        self.V[x] >>= 1;
    }
    /// Sets *Vx* to *Vy* - *Vx* and set *VF* to `!*borrow*`
    fn SUBN(self: *Chip8VM, x: u8, y: u8) void {
        self.V[0xF] = if (self.V[y] > self.V[x]) 1 else 0;
        self.V[x] = self.V[y] -% self.V[x];
    }
    /// Bitwise shift *Vx* left by one and set *VF* to 1 if least significant bit is 1
    fn SHL(self: *Chip8VM, x: u8) void {
        self.V[0xF] = self.V[x] & 128;
        self.V[x] <<= 1;
    }
    /// Skip next instruction if *Vx* != *Vy*
    fn SNEV(self: *Chip8VM, x: u8, y: u8) void {
        if (self.V[x] != self.V[y])
            self.PC += 2;
    }
    /// Sets *I* to *addr*
    fn LDI(self: *Chip8VM, addr: u16) void {
        self.I = addr;
    }
    /// Jump to address + V0
    fn JP(self: *Chip8VM, addr: u16) void {
        self.PC = addr + self.V[0];
    }
    /// Set *Vx* = *random byte* & *byte*
    fn RND(self: *Chip8VM, x: u8, byte: u8, rand: std.Random) void {
        self.V[x] = rand.intRangeAtMost(u8, 0, 255) & byte;
    }
    /// Display *n* byte sprite starting from location from *I* and drawn at *(Vx, Vy)* XOR'd to the screen, *VF* = collision
    fn DRW(self: *Chip8VM, x: u8, y: u8, n: u8) void {
        var index = 0;
        self.V[0xF] = 0;
        while (index < n) : (index += 1) {
            var sprite_row = u64(self.memory[self.I + index]) << (64 - 8 + self.V[x]);
            var current_row = self.display[self.V[y] + index];
            var new_row = current_row ^ sprite_row;
            if (current_row > current_row & new_row) {
                self.V[0xF] = 1;
            }
            self.display[self.V[y] + index] = new_row;
        }
    }
    /// Skip next instruction if key with value *Vx* is being pressed
    fn SKP(self: *Chip8VM, x: u8) void {
        if (self.keyboard & (1 << x) > 0)
            self.PC += 2;
    }
    /// Skip next instruction if key with value *Vx* is **NOT** being pressed
    fn SKNP(self: *Chip8VM, x: u8) void {
        if (self.keyboard & (1 << x) == 0)
            self.PC += 2;
    }
    /// Sets value of *DT* to register *Vx*
    fn LDVDT(self: *Chip8VM, x: u8) void {
        self.V[x] = self.DT;
    }
    /// Stop execution until a key press and store key in *Vx*
    fn LDVK(self: *Chip8VM, x: u8) void {
        // TODO: Implement when game loop is done.
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

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

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
