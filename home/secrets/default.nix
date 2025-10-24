{ inputs, user, ... }:

{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    age.keyFile = "/home/${user}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      gpg-private-key = {
        path = "/home/${user}/.gnupg/private.key";
        mode = "0600";
      };
      gpg-public-key = {
        path = "/home/${user}/.gnupg/public.key";
        mode = "0644";
      };
      signing-key = {
        path = "/home/${user}/.ssh/id_rsa";
        mode = "0600";
      };
      signing-pub-key = {
        path = "/home/${user}/.ssh/id_rsa.pub";
        mode = "0644";
      };
      zai-api-key = {
        mode = "0644";
      };

    };
  };

  home.file."/home/${user}/System/.sops.yaml".text = ''
    keys:
      - &primary age14zz7lfqlzx4grk28whm7eu8w4aecxytc9rpuee3qj8yu4yet7cws9law7x

    creation_rules:
      - path_regex: home/secrets/secrets.yaml$
        key_groups:
          - age:
              - *primary
  '';

  systemd.user.services.mbsync.Unit.After = [ "sops-nix.service" ];

  wayland.windowManager.hyprland.settings.exec-once = [ "systemctl --user start sops-nix" ];
}
