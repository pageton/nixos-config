{pkgs, ...}:
with pkgs; [
  dejavu_fonts # Fallback sans-serif font
  jetbrains-mono # Primary monospace font
  noto-fonts # Comprehensive font collection
  noto-fonts-lgc-plus # Extended language coverage
  texlivePackages.hebrew-fonts # Hebrew language support
  noto-fonts-color-emoji # Emoji font support
  font-awesome # Icon font for UI elements
  powerline-fonts # Special characters for status bars
  powerline-symbols # Additional powerline symbols
  nerd-fonts.jetbrains-mono # JetBrains Mono with Nerd Font patches
  meslo-lgs-nf
  fira-code
]
