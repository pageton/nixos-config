# NanoClaw — Rio Telegram bot (personal Claude assistant).
# Runs as a systemd user service on desktop only.
{ config, lib, pkgs, ... }:
let
  nanoclawDir = "${config.home.homeDirectory}/nanoclaw";
in
{
  systemd.user.services.nanoclaw = {
    Unit = {
      Description = "NanoClaw - Rio Telegram Bot";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      WorkingDirectory = nanoclawDir;
      ExecStart = "${pkgs.bun}/bin/bun ${nanoclawDir}/dist/index.js";
      EnvironmentFile = "${nanoclawDir}/.env";
      Restart = "on-failure";
      RestartSec = 10;

      # Hardening
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = [
        nanoclawDir
        # Claude Code needs access to its own data
        "${config.home.homeDirectory}/.claude"
      ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
