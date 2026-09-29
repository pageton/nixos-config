# Glance self-hosted dashboard (localhost:8082).
{
  config,
  lib,
  pkgs,
  constants,
  user,
  ...
}:
let
  glanceSettings = import ./settings.nix { inherit constants; };

  # Glance GitHub token bootstrap for authenticated widgets.
  # Uses the user's GitHub CLI auth, with hosts.yml token scraping as a fallback.
  glanceGithubToken = pkgs.writeShellScriptBin "glance-github-token" ''
    set -euo pipefail

    ${pkgs.coreutils}/bin/install -m 0700 -d /run/glance

    USER_UID=$(${pkgs.coreutils}/bin/id -u ${user})
    DBUS_SESSION_BUS_ADDRESS=
    if [ -S "/run/user/$USER_UID/bus" ]; then
      DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_UID/bus"
    fi

    if GH_TOKEN=$(${pkgs.util-linux}/bin/runuser -u ${user} -- ${pkgs.coreutils}/bin/env \
      HOME="/home/${user}" \
      XDG_CONFIG_HOME="/home/${user}/.config" \
      XDG_RUNTIME_DIR="/run/user/$USER_UID" \
      DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
      ${pkgs.gh}/bin/gh auth token 2>/dev/null) && [ -n "$GH_TOKEN" ]; then
      printf "GITHUB_TOKEN=%s\n" "$GH_TOKEN" > /run/glance/github-token.env
      exit 0
    fi

    TOKEN_FILE="/home/${user}/.config/gh/hosts.yml"
    if [ -f "$TOKEN_FILE" ]; then
      GH_TOKEN=$(${pkgs.gawk}/bin/awk "/oauth_token:/{print \$2}" "$TOKEN_FILE" | ${pkgs.coreutils}/bin/head -1)
      if [ -n "$GH_TOKEN" ]; then
        printf "GITHUB_TOKEN=%s\n" "$GH_TOKEN" > /run/glance/github-token.env
        exit 0
      fi
    fi
    echo "gh CLI not authenticated - GitHub widgets will not work"
    printf "GITHUB_TOKEN=\n" > /run/glance/github-token.env
  '';
in
{
  services.glance = {
    enable = true;
    openFirewall = false;
    environmentFile = "/run/glance/github-token.env";
    settings = glanceSettings;
  };

  systemd.services.glance.serviceConfig = {
    ExecStartPre = [ "+${glanceGithubToken}/bin/glance-github-token" ];
    EnvironmentFile = lib.mkForce "-/run/glance/github-token.env";
    # Only add the docker group where Docker is actually enabled (desktop).
    # On hosts without Docker (e.g. thinkpad) the group doesn't exist, which
    # makes systemd fail the unit with status 216/GROUP.
    SupplementaryGroups = lib.optionals config.virtualisation.docker.enable [ "docker" ];
  };
}
