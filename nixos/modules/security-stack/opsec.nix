# Operational security (session locking, NTS time).
# Extracted from security.nix.

{ lib, ... }:

{
  # Session lock on idle and lid-close — physical access protection
  services = {
    logind.settings.Login = {
      IdleAction = "lock";
      IdleActionSec = 300;
      HandleLidSwitch = "lock";
      HandleLidSwitchExternalPower = "lock";
      HandleLidSwitchDocked = "lock";
    };

    timesyncd.enable = lib.mkForce false;
    chrony = {
      enable = true;
      servers = [ ]; # NTS sources below instead of plain NTP
      extraConfig = ''
        server virginia.time.system.gov iburst nts
        server time.nist.gov iburst nts
        server nts.netnod.se iburst nts
        makestep 1.0 3
      '';
    };
  };

  # RAM-only swap — prevents sensitive data leaking to unencrypted partitions.
  # memoryPercent = 100 sizes the compressed device to match installed RAM
  # (30G on this host). zstd compresses ~3:1 on typical data, so effective
  # capacity is well above RAM; worst case (incompressible pages) the device
  # can still exhaust RAM, so vm.swappiness stays low (stability.nix) and
  # earlyoom guards the rest.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };
}
