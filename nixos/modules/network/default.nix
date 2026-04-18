# Networking — connectivity, VPN, DNS privacy, and anonymity.
{
  imports = [
    ../networking.nix # NetworkManager + systemd-resolved, SSH server
    ../dnscrypt-proxy.nix # Encrypted DNS via DNSCrypt (opt-in via mySystem.dnscryptProxy)
    ../mullvad.nix # Mullvad VPN with lockdown mode and quantum resistance (opt-in)
    ../tailscale.nix # Tailscale mesh VPN with loose RPF
    ../tor.nix # Tor client and torsocks (opt-in via mySystem.tor)
  ];
}
