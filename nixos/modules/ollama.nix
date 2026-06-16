# Ollama local LLM inference server.
{
  config,
  lib,
  pkgs,
  user,
  constants,
  ...
}:
let
  cfg = config.mySystem.ollama;

  pkgMap = {
    cuda = pkgs.ollama-cuda;
    rocm = pkgs.ollama-rocm;
    vulkan = pkgs.ollama-vulkan;
    null = pkgs.ollama;
  };

  modelsDir = "/var/lib/ollama/models";
in
{
  options.mySystem.ollama = {
    enable = lib.mkEnableOption "Ollama local LLM inference server";

    acceleration = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "cuda"
          "rocm"
          "vulkan"
        ]
      );
      default = null;
      description = "GPU acceleration (null = auto-detect, cuda, rocm, vulkan)";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = constants.localhost;
      description = "Host address to bind Ollama to";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = constants.ports.ollama;
      description = "Port for Ollama API";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgMap.${if cfg.acceleration == null then "null" else cfg.acceleration};
      host = cfg.host;
      port = cfg.port;
    };

    systemd.services.ollama.environment.OLLAMA_MODELS = modelsDir;

    systemd.tmpfiles.rules = [ "d ${modelsDir} 0775 ollama ollama -" ];

    users.users."${user}" = {
      extraGroups = [ "ollama" ];
    };
  };
}
