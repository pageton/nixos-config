# Local system packages for the 'thinkpad' host.
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    tlp # Power management
    smartmontools # Disk monitoring
    powertop # Power monitoring
  ];
}
