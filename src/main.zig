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

    fn init_sprites(self: *Chip8VM) void {
        // im so fucking lazy
        // im js gonna make gemini do this like its so damn boring
        // OOOOR GET PYTHON TO DO IT
        self.memory[0] = 0xF0;
        self.memory[1] = 0x90;
        self.memory[2] = 0x90;
        self.memory[3] = 0x90;
        self.memory[4] = 0xF0;
        self.memory[5] = 0x20;
        self.memory[6] = 0x60;
        self.memory[7] = 0x20;
        self.memory[8] = 0x20;
        self.memory[9] = 0x70;
        self.memory[10] = 0xF0;
        self.memory[11] = 0x10;
        self.memory[12] = 0xF0;
        self.memory[13] = 0x80;
        self.memory[14] = 0xF0;
        self.memory[15] = 0xF0;
        self.memory[16] = 0x10;
        self.memory[17] = 0xF0;
        self.memory[18] = 0x10;
        self.memory[19] = 0xF0;
        self.memory[20] = 0x90;
        self.memory[21] = 0x90;
        self.memory[22] = 0xF0;
        self.memory[23] = 0x10;
        self.memory[24] = 0x10;
        self.memory[25] = 0xF0;
        self.memory[26] = 0x80;
        self.memory[27] = 0xF0;
        self.memory[28] = 0x10;
        self.memory[29] = 0xF0;
        self.memory[30] = 0xF0;
        self.memory[31] = 0x80;
        self.memory[32] = 0xF0;
        self.memory[33] = 0x90;
        self.memory[34] = 0xF0;
        self.memory[35] = 0xF0;
        self.memory[36] = 0x10;
        self.memory[37] = 0x20;
        self.memory[38] = 0x40;
        self.memory[39] = 0x40;
        self.memory[40] = 0xF0;
        self.memory[41] = 0x90;
        self.memory[42] = 0xF0;
        self.memory[43] = 0x90;
        self.memory[44] = 0xF0;
        self.memory[45] = 0xF0;
        self.memory[46] = 0x90;
        self.memory[47] = 0xF0;
        self.memory[48] = 0x10;
        self.memory[49] = 0xF0;
        self.memory[50] = 0xF0;
        self.memory[51] = 0x90;
        self.memory[52] = 0xF0;
        self.memory[53] = 0x90;
        self.memory[54] = 0x90;
        self.memory[55] = 0xE0;
        self.memory[56] = 0x90;
        self.memory[57] = 0xE0;
        self.memory[58] = 0x90;
        self.memory[59] = 0xE0;
        self.memory[60] = 0xF0;
        self.memory[61] = 0x80;
        self.memory[62] = 0x80;
        self.memory[63] = 0x80;
        self.memory[64] = 0xF0;
        self.memory[65] = 0xE0;
        self.memory[66] = 0x90;
        self.memory[67] = 0x90;
        self.memory[68] = 0x90;
        self.memory[69] = 0xE0;
        self.memory[70] = 0xF0;
        self.memory[71] = 0x80;
        self.memory[72] = 0xF0;
        self.memory[73] = 0x80;
        self.memory[74] = 0xF0;
        self.memory[75] = 0xF0;
        self.memory[76] = 0x80;
        self.memory[77] = 0xF0;
        self.memory[78] = 0x80;
        self.memory[79] = 0x80;
        // HAHAHHAHHAHAH
    }

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
    fn JPV(self: *Chip8VM, addr: u16) void {
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
            const sprite_row = u64(self.memory[self.I + index]) << (64 - 8 + self.V[x]);
            const current_row = self.display[self.V[y] + index];
            const new_row = current_row ^ sprite_row;
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
    /// Sets value of register *Vx* to *DT*
    fn LDDTV(self: *Chip8VM, x: u8) void {
        self.DT = self.V[x];
    }
    /// Sets value of register *Vx* to *ST*
    fn LDSTV(self: *Chip8VM, x: u8) void {
        self.ST = self.V[x];
    }
    /// Increment register *I* by the value of *Vx*
    fn ADDI(self: *Chip8VM, x: u8) void {
        self.I +%= self.V[x];
    }
    fn LDIVX(self: *Chip8VM, x: u8) void {
        self.I = self.V[x] * 5;
    }
    /// Places the digits of *Vx* to I, I+1 and I+2
    fn LDBVX(self: *Chip8VM, x: u8) void {
        self.memory[self.I + 0] = self.V[x] / 100 % 10;
        self.memory[self.I + 1] = self.V[x] / 10 % 10;
        self.memory[self.I + 2] = self.V[x] / 1 % 10;
    }
    /// Stores values of *V0* to *Vx* starting from address at value of *I*
    fn LDIV0VX(self: *Chip8VM, x: u8) void {
        var index = 0;
        while (index <= x) : (index += 1) {
            self.memory[self.I + index] = self.V[index];
        }
    }
    /// Reads values starting at address of *I*s value to *V0* to *Vx*
    fn LDV0VXI(self: *Chip8VM, x: u8) void {
        var index = 0;
        while (index <= x) : (index += 1) {
            self.V[index] = self.memory[self.I + index];
        }
    }
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
