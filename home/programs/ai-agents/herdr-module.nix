# Local home-manager module for herdr.
# Adapted from https://github.com/pageton/herdr/feat/add-nix-support/nix/modules/hm/herdr.nix
# Uses upstream source-built package from the herdr flake input.

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.herdr;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.herdr = {
    enable = lib.mkEnableOption "herdr";

    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "herdr from upstream flake (source-built)";
      description = "The herdr package to use.";
    };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        theme.name = "catppuccin";
        terminal.default_shell = "${pkgs.zsh}/bin/zsh";
        ui.sidebar_width = 26;
        ui.mouse_capture = true;
        keys.prefix = "ctrl+b";
      };
      description = "Configuration written to ~/.config/herdr/config.toml.";
    };

    shellIntegration = {
      enable = lib.mkEnableOption "herdr shell integration" // {
        default = true;
      };

      zsh = {
        enable = lib.mkEnableOption "herdr zsh integration" // {
          default = config.programs.zsh.enable;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."herdr/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "herdr-config" cfg.settings;
    };

    programs.zsh.initContent =
      lib.mkIf (cfg.shellIntegration.enable && cfg.shellIntegration.zsh.enable)
        ''
          eval "$(herdr integration shell zsh 2>/dev/null || true)"
        '';
  };
}
