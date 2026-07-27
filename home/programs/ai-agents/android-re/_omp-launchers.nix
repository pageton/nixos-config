{
  config,
  constants,
  lib,
  pkgs,
}:

let
  scriptsDir = "${config.home.homeDirectory}/${constants.paths.scripts}";
  launcherScript = "${scriptsDir}/ai/android-re/omp-android-re.sh";

  mkOmpReLauncher =
    { name, profile }:
    pkgs.writeShellScriptBin name ''
      ANDROID_RE_OMP_PROFILE=${lib.escapeShellArg profile} \
        exec ${launcherScript} "$@"
    '';

in
map mkOmpReLauncher [
  {
    name = "ompre";
    profile = "default";
  }
  {
    name = "ompglmare";
    profile = "glm";
  }
  {
    name = "ompdeepare";
    profile = "deepseek";
  }
]
