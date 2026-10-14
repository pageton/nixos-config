# Zellij terminal multiplexer.
{
  imports = [
    ./plugins.nix # WASM plugin definitions and xdg.configFile entries
    ./layouts.nix # Layout definitions (default, dev, herdr, monitoring)
    ./config.nix # Zellij settings and keybinds
  ];
}
