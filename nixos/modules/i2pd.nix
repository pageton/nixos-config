# I2PD router service with optional firewall opening.
{ config, lib, ... }:
let
  cfg = config.mySystem.i2pd;
in
{
  options.mySystem.i2pd = {
    enable = lib.mkEnableOption "I2PD (I2P router) service";
    notransit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable transit tunnel participation to reduce relay traffic.";
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open TCP/UDP firewall rules for the configured i2pd port.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.i2pd = {
      enable = true;
      logLevel = lib.mkDefault "error";
      inherit (cfg) notransit;

      proto = {
        http.enable = lib.mkDefault true;
        httpProxy.enable = lib.mkDefault true;
        socksProxy.enable = lib.mkDefault true;
      };
    };
  };
}
