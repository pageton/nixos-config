# Maintenance — automated cleanup, backups, and Nix helper tools.
{
  imports = [
    ../cleanup.nix # Scheduled cleanup timers for downloads, caches, Docker (opt-in via mySystem.cleanup)
    ../backup.nix # Restic automated backups with retention (opt-in via mySystem.backup)
    ../nh.nix # nh (Nix Helper) + custom nix-validate wrapper
  ];
}
