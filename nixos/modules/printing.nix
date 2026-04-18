# CUPS printing services with privacy hardening.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.mySystem.printing = {
    enable = lib.mkEnableOption "CUPS printing services with network printer discovery";
  };

  config = lib.mkIf config.mySystem.printing.enable {
    services.printing = {
      enable = true;
      drivers = [ pkgs.foo2zjs ]; # Driver for HP LaserJet P1102
      listenAddresses = [ "127.0.0.1:631" ]; # Localhost only
      allowFrom = [ "localhost" ];
      extraConf = ''
        Browsing Off
        BrowseLocalProtocols none
        MaxJobs 10
        PreserveJobHistory No
        PreserveJobFiles No
      '';
    };
  };
}
