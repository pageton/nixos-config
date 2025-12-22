{
  lib,
  hostname,
  ...
}: {services.upower.enable = lib.mkDefault (hostname != "server");}
