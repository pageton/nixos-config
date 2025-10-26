{ inputs
, user
, pkgs
, ...
}:

{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    defaultSopsFormat = "yaml"; # Format of the secrets file
    validateSopsFiles = true; # Enable SOPS file validation
    defaultSopsFile = ./secrets.yaml; # Path to encrypted secrets file (relative to this module)

    age = {
      keyFile = "/home/${user}/.config/sops/age/keys.txt"; # Location of Age private key
      generateKey = false;
    };

    secrets = {
      gpg-private-key = {
        path = "/home/${user}/.gnupg/private.key";
      };
      gpg-public-key = {
        path = "/home/${user}/.gnupg/public.key";
      };
      signing-key = {
        path = "/home/${user}/.ssh/id_rsa";
      };
      signing-pub-key = {
        path = "/home/${user}/.ssh/id_rsa.pub";
      };
      zai-api-key = {
        path = "/home/${user}/.config/zai";
      };

      wakatime-api-key = { };

    };
  };

  systemd.user.services.mbsync.Unit.After = [ "sops-nix.service" ];

  home.packages = with pkgs; [
    sops
    age
  ];

  wayland.windowManager.hyprland.settings.exec-once = [ "systemctl --user start sops-nix" ];
}
