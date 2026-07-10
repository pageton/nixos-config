{
  config,
  constants,
  lib,
  pkgs,
}:

let
  scriptsDir = "${config.home.homeDirectory}/${constants.paths.scripts}";
  launcherScript = "${scriptsDir}/ai/android-re/mimo-android-re.sh";

  mkMimoReLauncher =
    { name, profile }:
    pkgs.writeShellScriptBin name ''
      ANDROID_RE_MIMO_PROFILE=${lib.escapeShellArg profile} \
        exec ${launcherScript} "$@"
    '';
in
map mkMimoReLauncher [
  {
    name = "miare";
    profile = "default";
  }
  {
    name = "miglmare";
    profile = "glm";
  }
  {
    name = "miskare";
    profile = "deepseek";
  }
]
