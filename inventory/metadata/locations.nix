# Server location metadata — committed to Git (public-safe).
#
# Maps location keys (used in servers.nix) to human-readable metadata.
# Locations themselves are not sensitive; the IP addresses that resolve
# to them are (and those live in DNS / SOPS, never here).
{
  nyc = {
    name = "New York";
    provider = "hetzner";
    region = "us-east";
  };
  fra = {
    name = "Frankfurt";
    provider = "hetzner";
    region = "eu-central";
  };
  # Add new locations as you provision servers in new regions.
}
