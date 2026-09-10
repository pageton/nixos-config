{
  inputs,
  user,
  lib,
  ...
}:
let
  # sops-install-secrets fails the whole build for any declared secret whose
  # key is missing from the sops file, so gpg-passphrase is declared only when
  # present. Adding it later (`just secrets-add gpg-passphrase`) activates the
  # gpg-preset-passphrase service (home/programs/gpg.nix) on the next rebuild.
  secretsYaml = builtins.readFile ../../secrets/secrets.yaml;
  hasSecret = key: lib.hasPrefix "${key}:" secretsYaml || lib.hasInfix "\n${key}:" secretsYaml;
in
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
      opencode_zen_api_key = {
        owner = user;
        mode = "0400";
      };
      deepseek_api_key = {
        owner = user;
        mode = "0400";
      };
      mimo_api_key = {
        owner = user;
        mode = "0400";
      };
    }
    // lib.optionalAttrs (hasSecret "gpg-passphrase") {
      # Signing-key passphrase, fed to gpg-agent at login by the
      # gpg-preset-passphrase user service (home/programs/gpg.nix) so commit
      # signing never prompts. Requires allow-preset-passphrase in the agent.
      gpg-passphrase = {
        owner = user;
        mode = "0400";
      };
    };
  };
}
