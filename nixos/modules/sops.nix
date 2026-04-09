{ inputs, user, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFormat = "yaml";
    validateSopsFiles = true;
    defaultSopsFile = ../../secrets/secrets.yaml;

    age = {
      keyFile = "/home/${user}/.config/sops/age/keys.txt";
      generateKey = false;
    };

    secrets = {
      gpg-private-key = {
        owner = user;
        path = "/home/${user}/.gnupg/private.key";
        mode = "0400";
      };
      gpg-public-key = {
        owner = user;
        path = "/home/${user}/.gnupg/public.key";
        mode = "0400";
      };
      ssh-private-key = {
        owner = user;
        path = "/home/${user}/.ssh/id_ed25519";
        mode = "0400";
      };
      ssh-public-key = {
        owner = user;
        path = "/home/${user}/.ssh/id_ed25519.pub";
        mode = "0400";
      };
      zai_api_key = {
        owner = user;
        mode = "0400";
      };
      context7-api-key = {
        owner = user;
        mode = "0400";
      };
      wakatime-api-key = {
        owner = user;
        mode = "0400";
      };
      openrouter_api_key = {
        owner = user;
        mode = "0400";
      };
    };
  };
}
