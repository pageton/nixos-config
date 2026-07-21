# Tag definitions — committed to Git (public-safe).
#
# Documents the set of valid tag keys and their possible values.
# Tags are arbitrary key-value pairs on server entries (servers.nix `tags`).
# This file serves as documentation and can be used for validation.
{
  # Environment classification.
  env = [
    "production"
    "staging"
    "development"
    "ci"
  ];

  # Service tier / layer.
  tier = [
    "frontend"
    "backend"
    "data"
    "infra"
  ];

  # Whether the server is ephemeral (created/destroyed frequently).
  ephemeral = [
    "true"
    "false"
  ];
}
