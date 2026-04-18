# Core system modules — boot, package manager, users, secrets, locale, and stability.
{
  imports = [
    ../bootloader.nix # GRUB with EFI, kernel package selection
    ../nix.nix # Nix daemon settings, flakes, GC, substituters
    ../users.nix # User account, groups, shell, SSH authorized keys
    ../sops.nix # SOPS + age secret decryption paths
    ../timezone.nix # System timezone
    ../i18n.nix # Locale and LC_* overrides
    ../environment.nix # Session variables (TERMINAL, EDITOR, XDG, Java Wayland fix)
    ../stability.nix # earlyoom, TCP BBR, inotify limits, PAM limits, fstrim
    ../validation.nix # Cross-module conflict assertions (audio, graphics, VPN, etc.)
  ];
}
