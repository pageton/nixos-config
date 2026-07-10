{
  lib,
  pkgs,
  scriptsDir,
}:

let
  launcherScript = "${scriptsDir}/ai/web-re/mimo-web-re.sh";

  mkMimoReLauncher =
    { name, profile }:
    pkgs.writeShellScriptBin name ''
      WEB_RE_MIMO_PROFILE=${lib.escapeShellArg profile} \
        exec ${launcherScript} "$@"
    '';
in
map mkMimoReLauncher [
  {
    name = "miwre";
    profile = "default";
  }
  {
    name = "miglmwre";
    profile = "glm";
  }
  {
    name = "miskwre";
    profile = "deepseek";
  }
]
