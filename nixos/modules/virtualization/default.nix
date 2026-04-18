# Virtualization and binary compatibility.
{
  imports = [
    ../virtualisation.nix # Docker, VirtualBox, libvirt, Waydroid (opt-in via mySystem.virtualisation)
    ../nix-ld.nix # Run non-NixOS dynamically linked binaries via nix-ld
  ];
}
