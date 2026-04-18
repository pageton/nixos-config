# Security stack — kernel hardening, sandboxing, application firewall, MAC randomization.
{
  imports = [
    ../security.nix # Kernel params, sysctl, firewall, nftables, AIDE, Chrony, AppArmor, journald
    ../sandboxing.nix # Firejail wrapped binaries with per-app profiles (opt-in)
    ../opensnitch.nix # Per-app network firewall with eBPF monitoring (opt-in)
    ../macchanger.nix # MAC address randomization on boot (opt-in)
  ];
}
