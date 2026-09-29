# Mullvad VPN with hardened tunnel settings (desktop host only).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  mullvad = "${config.services.mullvad-vpn.package}/bin/mullvad";

  mullvadSettingsScript = pkgs.writeShellScript "mullvad-settings" ''
    # Wait for mullvad daemon RPC socket to be ready
    for i in $(seq 1 30); do
      ${mullvad} status >/dev/null 2>&1 && break
      sleep 1
    done

    # === DNS ===
    # Do not set Mullvad-side custom DNS. The host resolves through
    # NetworkManager/systemd-resolved. Forcing Mullvad's tunnel DNS adds
    # unnecessary complexity and can slow tunnel establishment.
    ${mullvad} dns set default

    # === Kill Switch ===
    # Block ALL traffic when VPN is disconnected. No leaks.
    ${mullvad} lockdown-mode set on

    # === Auto-connect ===
    # Reconnect VPN automatically on boot/network change.
    ${mullvad} auto-connect set on

    # === Relay Selection ===
    # Prefer the currently reliable nearby region instead of `location any`.
    # Random far-away relays caused repeated WireGuard timeout/obfuscation
    # loops during boot before eventually landing on Netherlands anyway.
    ${mullvad} relay set multihop off
    ${mullvad} relay set location nl

    # === Tunnel Hardening ===
    # Quantum-resistant key exchange (post-quantum crypto on top of WireGuard)
    ${mullvad} tunnel set quantum-resistant on
    # DAITA disabled: from Jordan, DAITA + obfuscation causes connection failures.
    # Mullvad auto-disables it after repeated failures anyway. Re-enable on
    # unrestricted networks where direct WireGuard works.
    ${mullvad} tunnel set daita off
    # Disable IPv6 inside Mullvad tunnel (Yggdrasil can still use kernel IPv6 stack)
    ${mullvad} tunnel set ipv6 off
    # Rotate WireGuard keys every 24 hours for forward secrecy
    ${mullvad} tunnel set rotation-interval 24

    # === Obfuscation ===
    # Auto-detect censorship and apply obfuscation when needed.
    ${mullvad} obfuscation set mode auto

    # === Local Network ===
    # Allow LAN access: Flatpak apps and local services need it.
    # On public/hostile networks LAN access is an attack surface — tighten
    # to `lan set block` if not running local services.
    ${mullvad} lan set allow
  '';
in
{
  services.mullvad-vpn = {
    enable = true;
    gui.enable = true;
  };

  # Mullvad's packaged unit waits for network-online, which adds ~14s of
  # boot delay via NetworkManager-wait-online. Starting after NetworkManager
  # is sufficient; the daemon can reconnect as soon as the link is usable.
  systemd.services.mullvad-daemon = {
    wants = lib.mkForce [ "network.target" ];
    after = lib.mkForce [
      "network.target"
      "NetworkManager.service"
    ];
  };

  # Declarative settings applied after daemon starts
  systemd.services.mullvad-settings = {
    description = "Apply declarative Mullvad VPN settings";
    after = [ "mullvad-daemon.service" ];
    requires = [ "mullvad-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = "${mullvadSettingsScript}";
  };
}
