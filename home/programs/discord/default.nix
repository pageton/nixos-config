# Discord configuration for NixOS
{inputs, ...}: {
  imports = [inputs.nixcord.homeModules.nixcord];

  programs.nixcord = {
    enable = true;
    vesktop.enable = true;
    config = {
      frameless = true;
    };
  };
}
