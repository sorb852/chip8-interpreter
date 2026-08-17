//! hey its me its verity
//! ask me anything
//! i know about a million things
//! some oui oui type shi
//! shi
//! merci
//! whats the capital of france
//! what does the cow say
//! moo moo moo moo
//! i speak that too

const std = @import("std");

/// Chip8 virtual machine. ie, the backend.
/// Handles most of the action.
/// Running games, "*managing*" memory, storing registers and all that.
pub const Chip8VM = struct {
    /// Starts main game memory at 512
    memory: [4096]u8 = [0]**4096,
    /// *V* registers, from *V0* to *VF*
    V: [16]u8 = [0]**16,
    /// *I* register
    I: u16 = 0,
    /// Delay timer
    DT: u8 = 0,
    /// Sound timer, use on the frontend to play a tune when non zero.
    ST: u8 = 0,
    /// Program counter
    PC: u16 = 512,
    /// Stack counter
    SP: u8 = 0,
    stack: [16]u16 = [0]**16,
    /// Keypad represented as such
    /// Shift to get placement of the pad
    /// ```
    /// 123C
    /// 456D
    /// 789E
    /// A0BF
    /// ```
    /// To get the top middle (2), you must *keyboard* & (1 << 2) to get if the key is pressed or not
    keyboard: u16 = 0,
    /// Stores the display. Each row of pixels is a bit represented using unsigned 64 bit integer
    display: u64[32] = [0]**32,

    // Interpreter related

    /// The rng of the Chip8, set as you please.
    rand: std.Random,

    /// Tells the frontend of the interpreter to redraw.
    /// Dont wanna be redrawing everything would you?
    needs_redraw: bool = true,
    /// For instruction LDVK (Fx0A)
    waiting_for_keypress: bool = false,
    /// Paired with `waiting_for_keypress`.
    /// Stores which register to write to.
    to_set_keypress_to: u4 = 0,

    finished: bool = true,

    // Methods

    /// Loads the ROM code into memory.
    /// Given a reader to the file.
    fn init_rom(self: *Chip8VM, reader: *std.Io.Reader) void {
        // ok so had to gemini this one
        try reader.readSliceShort(&self.memory[512..]);
        self.finished = false;
    }

    /// Initialize the hex sprites.
    /// Starts from 0 to 79, with each sprite having 5 bytes.
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

    /// Tick the interpreter state. Should be run every at 1/60th of a second.
    /// This will tick the timers
    fn tick(self: *Chip8VM) void {
        if (self.finished) return;

        self.DT -= if (self.DT > 0) 1 else 0;
        self.ST -= if (self.ST > 0) 1 else 0;

        // TODO: wtf is this ethical?
        // like should the timer and running instructions be separate?
        // yeahh i think so
        // lets just make it up to the frontend
        // how about that?
        run_instruction(self.memory[self.PC]);

        // TODO: implement a better way to check for exit
        if (self.PC >= 0x200 and self.memory[self.PC] == 0)
            self.finished = true;
    }
    /// Poll input and change state.
    /// Call as many times as you want.
    ///
    /// ok obviously not like 2 billion times a second
    fn poll_input(self: *Chip8VM, key: u4) void {
        self.keyboard |= 1 << key;
        if (self.waiting_for_keypress) {
            self.waiting_for_keypress = false;
            self.V[self.to_set_keypress_to] = key;
        }
    }
    /// Runs current insturction at PC.
    /// With the exception being when LDVK. Which doesn't do anything.
    fn run_instruction(self: *Chip8VM) void {
        if (self.waiting_for_keypress) return;

        // values of the instruction
        const instruction: u16 = u16(self.memory[self.PC]) << 8 + self.memory[self.PC + 1];
        const header: u4 = self.memory[self.PC] >> 4;
        const addr: u12 = (u12(self.memory[self.PC] % 0x10) << 8) + self.memory[self.PC + 1];
        const nibble: u12 = self.memory[self.PC + 1] % 0x10;
        const x: u4 = self.memory[self.PC] % 0x10;
        const y: u4 = self.memory[self.PC + 1] >> 4;
        const byte: u8 = self.memory[self.PC + 1];

        var matched_instruction = true;

        switch (header) {
            0x0 => {
                switch (instruction) {
                    0x00E0 => self.CLS(),
                    0x00EE => self.RET(),
                    else => matched_instruction = false,
                }
            },
            0x1 => self.JP(addr),
            0x2 => self.CALL(addr),
            0x3 => self.SE(x, byte),
            0x4 => self.SNE(x, byte),
            0x5 => self.SEV(x, y),
            0x6 => self.LD(x, byte),
            0x7 => self.ADD(x, byte),
            0x8 => switch (nibble) {
                0x0 => self.LDV(x, y),
                0x1 => self.OR(x, y),
                0x2 => self.AND(x, y),
                0x3 => self.XOR(x, y),
                0x4 => self.ADDV(x, y),
                0x5 => self.SUB(x, y),
                0x6 => self.SHR(x, y),
                0x7 => self.SUBN(x, y),
                0xE => self.SHL(x, y),
                else => matched_instruction = false,
            },
            0x9 => self.SNE(x, y),
            0xA => self.LDI(addr),
            0xB => self.JPV(addr),
            0xC => self.RND(x, byte),
            0xD => self.DRW(x, y, nibble),
            0xE => switch (byte) {
                0x9E => self.SKP(x),
                0xA1 => self.SKNP(x),
                else => matched_instruction = false,
            },
            0xF => switch (byte) {
                0x07 => self.LDVDT(x),
                0x0A => self.LDVK(x),
                0x15 => self.LDDTV(x),
                0x18 => self.LDSTV(x),
                0x1E => self.ADDI(x),
                0x29 => self.LDIVX(x),
                0x33 => self.LDBVX(x),
                0x55 => self.LDIV0VX(x),
                0x65 => self.LDV0VXI(x),
                else => matched_instruction = false,
            },
            else => matched_instruction = false,
        }

        if (matched_instruction)
            self.PC += 1;
    }

    // Instruction API

    /// Clear screen
    /// 00E0 - CLS
    fn CLS(self: *Chip8VM) void {
        for (&self.display) |*row| row.* = 0;
        self.needs_redraw = true;
    }
    /// Return from subroutine
    /// 00EE - RET
    fn RET(self: *Chip8VM) void {
        self.PC = self.stack[self.SP];
        self.SP -= if (self.SP > 0) 1 else 0;
    }
    /// Jump to address
    /// 1nnn - JP addr
    fn JP(self: *Chip8VM, addr: u12) void {
        self.PC = addr;
    }
    /// Call a subroutine
    /// 2nnn - CALL addr
    fn CALL(self: *Chip8VM, addr: u12) void {
        self.SP += 1;
        self.stack[self.SP] = self.PC;
        self.PC = addr;
    }
    /// Skip next instruction if *Vx* == byte
    /// 3xkk - SE Vx, byte
    fn SE(self: *Chip8VM, x: u4, byte: u8) void {
        if (self.V[x] == byte)
            self.PC += 1;
    }
    /// Skip next instruction if *Vx* != byte
    /// 4xkk - SNE Vx, byte
    fn SNE(self: *Chip8VM, x: u4, byte: u8) void {
        if (self.V[x] != byte)
            self.PC += 1;
    }
    /// Skip next instruction if *Vx* == *Vy*
    /// 5xy0 - SE Vx, Vy
    fn SEV(self: *Chip8VM, x: u4, y: u4) void {
        if (self.V[x] == self.V[y])
            self.PC += 1;
    }
    /// Sets a value to register *Vx*
    /// 6xkk - LD Vx, byte
    fn LD(self: *Chip8VM, x: u4, byte: u8) void {
        self.V[x] = byte;
    }
    /// Increment register *Vx* by a value
    /// 7xkk - ADD Vx, byte
    fn ADD(self: *Chip8VM, x: u4, byte: u8) void {
        self.V[x] +%= byte;
    }
    /// Sets *Vx* to *Vy*
    /// 8xy0 - LD Vx, Vy
    fn LDV(self: *Chip8VM, x: u4, y: u4) void {
        self.V[x] = self.V[y];
    }
    /// Sets *Vx* to *Vx* | *Vy*
    /// 8xy1 - OR Vx, Vy
    fn OR(self: *Chip8VM, x: u4, y: u4) void {
        self.V[x] |= self.V[y];
    }
    /// Sets *Vx* to *Vx* & *Vy*
    /// 8xy2 - AND Vx, Vy
    fn AND(self: *Chip8VM, x: u4, y: u4) void {
        self.V[x] &= self.V[y];
    }
    /// Sets *Vx* to *Vx* ^ *Vy*
    /// 8xy3 - XOR Vx, Vy
    fn XOR(self: *Chip8VM, x: u4, y: u4) void {
        self.V[x] ^= self.V[y];
    }
    /// Sets *Vx* to *Vx* + *Vy* and *VF* as the carry out
    /// 8xy4 - ADD Vx, Vy
    fn ADDV(self: *Chip8VM, x: u4, y: u4) void {
        const added = self.V[x] +% self.V[y];
        self.V[0xF] = if (added < self.V[x]) 1 else 0;
        self.V[x] = added;
    }
    /// Sets *Vx* to *Vx* - *Vy* and set *VF* to `!*borrow*`
    /// 8xy5 - SUB Vx, Vy
    fn SUB(self: *Chip8VM, x: u4, y: u4) void {
        self.V[0xF] = if (self.V[x] > self.V[y]) 1 else 0;
        self.V[x] -%= self.V[y];
    }
    /// Bitwise shift *Vx* left by one and set *VF* to 1 if least significant bit is 1
    /// 8xy6 - SHR Vx {, Vy}
    fn SHR(self: *Chip8VM, x: u4, y: u4) void {
        _ = y; // yes, y is not used. but its part of the operation so i guess well keep it? (genuinely why did they do this)
        self.V[0xF] = self.V[x] & 1;
        self.V[x] >>= 1;
    }
    /// Sets *Vx* to *Vy* - *Vx* and set *VF* to `!*borrow*`
    /// 8xy7 - SUBN Vx, Vy
    fn SUBN(self: *Chip8VM, x: u4, y: u4) void {
        self.V[0xF] = if (self.V[y] > self.V[x]) 1 else 0;
        self.V[x] = self.V[y] -% self.V[x];
    }
    /// Bitwise shift *Vx* left by one and set *VF* to 1 if most significant bit is 1
    /// 8xyE - SHL Vx {, Vy}
    fn SHL(self: *Chip8VM, x: u4, y: u4) void {
        _ = y; // yes, y is not used. but its part of the operation so i guess well keep it? (genuinely why did they do this)
        self.V[0xF] = (self.V[x] & 128) >> 7;
        self.V[x] <<= 1;
    }
    /// Skip next instruction if *Vx* != *Vy*
    /// 9xy0 - SNE Vx, Vy
    fn SNEV(self: *Chip8VM, x: u4, y: u4) void {
        if (self.V[x] != self.V[y])
            self.PC += 1;
    }
    /// Sets *I* to *addr*
    /// Annn - LD I, addr
    fn LDI(self: *Chip8VM, addr: u12) void {
        self.I = addr;
    }
    /// Jump to address + V0
    /// Bnnn - JP V0, addr
    fn JPV(self: *Chip8VM, addr: u12) void {
        self.PC = addr + self.V[0];
    }
    /// Set *Vx* = *random byte* & *byte*
    /// Cxkk - RND Vx, byte
    // TODO: make rand part of the VM rather than the instruction
    fn RND(self: *Chip8VM, x: u4, byte: u8) void {
        self.V[x] = self.rand.intRangeAtMost(u8, 0, 255) & byte;
    }
    /// Display *n* byte sprite starting from location from *I* and drawn at *(Vx, Vy)* XOR'd to the screen, *VF* = collision
    /// Dxyn - DRW Vx, Vy, nibble
    fn DRW(self: *Chip8VM, x: u4, y: u4, nibble: u4) void {
        var index: u4 = 0;
        self.V[0xF] = 0;
        while (index < nibble) : (index += 1) {
            const sprite_row = u64(self.memory[self.I + index]) << (64 - 8 - self.V[x]);
            const current_row = self.display[self.V[y] + index];
            const new_row = current_row ^ sprite_row;
            if (current_row > current_row & new_row)
                self.V[0xF] = 1;
            self.display[self.V[y] + index] = new_row;
        }
        self.needs_redraw = true;
    }
    /// Skip next instruction if key with value *Vx* is being pressed
    /// Ex9E - SKP Vx
    fn SKP(self: *Chip8VM, x: u4) void {
        if (self.keyboard & (1 << self.V[x]) > 0)
            self.PC += 1;
    }
    /// Skip next instruction if key with value *Vx* is **NOT** being pressed
    /// ExA1 - SKNP Vx
    fn SKNP(self: *Chip8VM, x: u4) void {
        if (self.keyboard & (1 << self.V[x]) == 0)
            self.PC += 1;
    }
    /// Sets value of *DT* to register *Vx*
    /// Fx07 - LD Vx, DT
    fn LDVDT(self: *Chip8VM, x: u4) void {
        self.V[x] = self.DT;
    }
    /// Stop execution until a key press and store key in *Vx*
    /// Fx0A - LD Vx, K
    fn LDVK(self: *Chip8VM, x: u4) void {
        self.waiting_for_keypress = true;
        self.to_set_keypress_to = x;
    }
    /// Sets value of register *Vx* to *DT*
    /// Fx15 - LD DT, Vx
    fn LDDTV(self: *Chip8VM, x: u4) void {
        self.DT = self.V[x];
    }
    /// Sets value of register *Vx* to *ST*
    /// Fx18 - LD ST, Vx
    fn LDSTV(self: *Chip8VM, x: u4) void {
        self.ST = self.V[x];
    }
    /// Increment register *I* by the value of *Vx*
    /// Fx1E - ADD I, Vx
    fn ADDI(self: *Chip8VM, x: u4) void {
        self.I +%= self.V[x];
    }
    /// Sets *I* to the digit sprite of *Vx*
    /// Fx29 - LD F, Vx
    fn LDIVX(self: *Chip8VM, x: u4) void {
        self.I = self.V[x] * 5;
    }
    /// Places the digits of *Vx* to I, I+1 and I+2
    /// Fx33 - LD B, Vx
    fn LDBVX(self: *Chip8VM, x: u4) void {
        self.memory[self.I + 0] = self.V[x] / 100 % 10;
        self.memory[self.I + 1] = self.V[x] / 10 % 10;
        self.memory[self.I + 2] = self.V[x] / 1 % 10;
    }
    /// Stores values of *V0* to *Vx* starting from address at value of *I*
    /// Fx55 - LD [I], Vx
    fn LDIV0VX(self: *Chip8VM, x: u4) void {
        var index = 0;
        while (index <= x) : (index += 1) {
            self.memory[self.I + index] = self.V[index];
        }
    }
    /// Reads values starting at address of *I*s value to *V0* to *Vx*
    /// Fx65 - LD Vx, [I]
    fn LDV0VXI(self: *Chip8VM, x: u4) void {
        var index = 0;
        while (index <= x) : (index += 1) {
            self.V[index] = self.memory[self.I + index];
        }
    }
};
