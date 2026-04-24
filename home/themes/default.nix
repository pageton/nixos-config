# Theme configuration — options and Stylix theming.
# Palette is a plain attrset (not a module) imported directly by stylix.nix.
{ ... }:
{
  imports = [
    ./options.nix # Theme submodule options (rounding, gaps, opacity, bar, etc.)
    ./stylix.nix # Stylix config: fonts, cursor, icons, wallpaper, targets
  ];
}
