{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    tlp # Power management
    smartmontools # Disk monitoring
    powertop # Power monitoring
  ];
}
