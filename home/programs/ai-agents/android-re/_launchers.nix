{
  config,
  constants,
  lib,
  pkgs,
}:

let
  scriptsDir = "${config.home.homeDirectory}/${constants.paths.scripts}";
  launcherScript = "${scriptsDir}/ai/android-re/opencode-android-re.sh";

  mkAndroidReLauncher =
    { name, profile }:
    pkgs.writeShellScriptBin name ''
      ANDROID_RE_OPENCODE_PROFILE=${lib.escapeShellArg profile} \
        exec ${launcherScript} "$@"
    '';

in
map mkAndroidReLauncher [
  {
    name = "ocare";
    profile = "default";
  }
  {
    name = "ocglmare";
    profile = "glm";
  }
  {
    name = "ocgemare";
    profile = "gemini";
  }
  {
    name = "ocgptare";
    profile = "gpt";
  }
  {
    name = "ocorare";
    profile = "openrouter";
  }
  {
    name = "ocsare";
    profile = "sonnet";
  }
  {
    name = "oczenare";
    profile = "zen";
  }
]
++ map mkAndroidReLauncher [
  {
    name = "ocoare";
    profile = "default";
  }
  {
    name = "ocoglmare";
    profile = "omo-glm";
  }
  {
    name = "ocogemare";
    profile = "omo-gemini";
  }
  {
    name = "ocogptare";
    profile = "omo-gpt";
  }
  {
    name = "ocoorare";
    profile = "omo-openrouter";
  }
  {
    name = "ocosare";
    profile = "omo-sonnet";
  }
  {
    name = "ocozenare";
    profile = "omo-zen";
  }
]
