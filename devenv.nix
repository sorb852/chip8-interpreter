{ pkgs, ... }:
{
  packages = with pkgs; [
    libGLU
    libx11
    libxrandr
    libxinerama
    libxi
    libxcursor
  ];
  languages = {
    zig.enable = true;
  };
}
