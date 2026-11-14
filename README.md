# Chopped

A chip-8 interpreter written in Zig. Thought learning zig and gettig into even lower level code at the same time would be fun.

I guess you could say it was fun. (ignore the commits, or better yet, find my 7 iq pages)

The zig version used in this project is v0.16.0 and depends on [raylib-zig](https://github.com/raylib-zig/raylib-zig).

<!-- TODO: add a gif or something might be cool -->

# Usage

## Compilation

```bash
zig build                          # Building the binary
zig build -Doptimize=ReleaseSafe   # Building the optimized binary

zig build run -- --help            # To display help information
zig build run -- roms/ibm.ch8      # To run a rom directly
```

## CLI

Result of `chopped --help`.

```
Usage: chopped [OPTIONS] <FILE>

Arguments:
        <FILE>   The chip8 file to be executed.

Options:
        --help, -h                            Display help information.
        --fg <HEX_COLOR>                      Change the foreground of the program. Default #ffffff.
        --bg <HEX_COLOR>                      Change the background of the program. Default #000000.
        --disable-raylib-logging              Disable raylib logs.
        --scale <SCALE>, -s <SCALE>           Change the size of each pixel. Default 16px.
        --target-tickrate <RATE>, -t <RATE>   Change the tick rate of the emulator. Default 240Hz.
```

## Input

The inputs are mapped as:

```
1234
QWER
ASDF
ZXCV
```

for chip8 binds:

```
123C
456D
789E
A0BF
```

# API

## Initialization

The "VM" (it sounds cooler than emulator) can be accessed via `@import("chopped").vm.Chip8VM`. Usage requires an `std.Random` to be set and `Chip8VM.init_rom` ran with an `std.Io.Reader` to a file, and `Chip8VM.init_sprites`.

## Execution

There is a `Chip8VM.tick_timers` function that should be called at **60Hz** and a `Chip8VM.step` function that can be called however fast you want. The step function is the fetch, decode, execute cycle of the emulator.

`Chip8VM.poll_input` should also be called at whatever speeds and takes the index of the key (0x0-0xF corresponding to the chip8 keyboard input). Here is also where instructions like `Fx0A` waits for key presses.

# Acknowledgements and sources

Thanks to these resources and people I have been able to make this project. Thank you!

* [Cowgod's Chip-8 Technical Reference v1.0](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM)
* [Roms from loktar00's chip8 emulator](https://github.com/loktar00/chip8/tree/master/roms)
