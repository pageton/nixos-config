# Top-level inventory aggregator — committed to Git.
#
# Exports the complete server inventory for consumption by:
#   - flake.nix (nixosConfigurations)
#   - Deployment tools (deploy-rs, nixos-anywhere, custom scripts)
#
# Real server IPs live in gitignored servers.nix files (force-added locally).
# Template files (.nix.example) are committed as documentation.
#
# First-clone setup:
#   cp inventory/permanent/servers.nix.example inventory/permanent/servers.nix
#   cp inventory/ephemeral/servers.nix.example  inventory/ephemeral/servers.nix
#   # Fill in real IPs, then:
#   git add -f inventory/permanent/servers.nix inventory/ephemeral/servers.nix
{
  # Permanent servers (hostname, ip, roles, tags)
  permanent = import ./permanent;

  # Ephemeral servers (frequently created/destroyed)
  ephemeral = import ./ephemeral;

  # Public metadata (no IPs — safe to commit)
  metadata = {
    locations = import ./metadata/locations.nix;
    roles = import ./metadata/roles.nix;
    tags = import ./metadata/tags.nix;
  };

  # Convenience: all servers combined
  all = (import ./permanent) ++ (import ./ephemeral);
}
