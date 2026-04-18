# Mise polyglot runtime manager.

{ config, ... }:

{
  programs.mise = {
    enable = true;
    globalConfig.settings = {
      experimental = true;
      verbose = false;
      quiet = false;
      disable_tools = [ "python" ];
    };
  };

  home.sessionVariables = {
    MISE_EXPERIMENTAL = "1";
    MISE_TELEMETRY = "0";
  };

  home.sessionPath = [ "${config.home.homeDirectory}/.local/share/mise/shims" ];
}
