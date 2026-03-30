{
  inputs,
  user,
  ...
}:
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
      };
      gpg-public-key = {
        owner = user;
        path = "/home/${user}/.gnupg/public.key";
      };
      ssh-private-key = {
        owner = user;
        path = "/home/${user}/.ssh/id_ed25519";
        neededForUsers = true;
      };
      ssh-public-key = {
        owner = user;
        path = "/home/${user}/.ssh/id_ed25519.pub";
      };
      zai_api_key = {
        owner = user;
        path = "/run/secrets/zai_api_key";
      };
      context7-api-key = {
        owner = user;
      };
      wakatime-api-key = {
        owner = user;
      };
    };
  };
}
