# Sunshine game-streaming host for Moonlight clients (ported from yzua).
# Wayland (wlr) capture under Niri; NVIDIA NVENC via the CUDA build.
# Firewall: Sunshine ports only on the physical LAN interface (eno1) and never
# the web UI port 47990; tailscale0 is already fully trusted in security.nix,
# so Moonlight clients on the tailnet need no additional rules.
{
  config,
  lib,
  pkgs,
  user,
  ...
}:

{
  services.sunshine = {
    enable = true;
    autoStart = true;
    openFirewall = false;
    # The cached non-CUDA build cannot complete its NVENC frame conversion test.
    package = pkgs.sunshine.override { cudaSupport = true; };
    # Niri implements the wlr screencopy protocol; no privileged KMS wrapper needed.
    capSysAdmin = false;
    settings = {
      sunshine_name = config.networking.hostName;
      address_family = "ipv4";
      # Keep loopback available for the local-only administration interface.
      origin_web_ui_allowed = "pc";
      upnp = "disabled";
      lan_encryption_mode = 2;
      wan_encryption_mode = 2;
      capture = "wlr";
      encoder = "nvenc";
      controller = "enabled";
      # Standard XInput mapping works across Steam/Proton games, regardless of
      # the physical controller paired with the streaming client.
      gamepad = "x360";
    };
    applications.apps = [
      { name = "Desktop"; }
      {
        name = "Steam Big Picture";
        detached = [ "${lib.getExe config.programs.steam.package} -bigpicture" ];
      }
    ];
  };

  # Pair by address (Moonlight manual host entry); no mDNS service announcements.
  # The upstream Sunshine module still assigns the legacy avahi publish options
  # (publish.enable/userServices) via mkDefault, which nixpkgs flags as obsolete;
  # null them out — publishing is disabled through the settings API below, so
  # the legacy values are unused.
  services.avahi.publish.enable = lib.mkForce null;
  services.avahi.publish.userServices = lib.mkForce null;
  # Sunshine enables avahi-daemon; keep it on the LAN interface only, matching
  # the firewall scoping above (validation.nix enforces an explicit list).
  services.avahi.settings.server.allow-interfaces = [ "eno1" ];
  services.avahi.settings.publish."disable-publishing" = true;

  systemd.user.services.sunshine = {
    unitConfig.ConditionUser = user;
    serviceConfig.UMask = "0077";
  };

  # Never use the module's global port openings, nor expose its web UI (47990).
  networking.firewall.interfaces.eno1 = {
    allowedTCPPorts = [
      47984 # HTTPS
      47989 # HTTP
      48010 # RTSP
    ];
    allowedUDPPorts = [
      47998 # Video
      47999 # Video (encrypted)
      48000 # Control
      48002 # Audio/extra
      48010 # RTSP (UDP fallback)
    ];
  };
}
