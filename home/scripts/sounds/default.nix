{ pkgs, ... }:
let
  increments = "5";
  sound-change = pkgs.writeShellScriptBin "sound-change" ''
    [[ $1 == "mute" ]] && wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    [[ $1 == "up" ]] && {
      current=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
      increment=''${2-${increments}}
      new_volume=$((current + increment))
      [[ $new_volume -gt 100 ]] && new_volume=100
      wpctl set-volume @DEFAULT_AUDIO_SINK@ ''${new_volume}%
    }
    [[ $1 == "down" ]] && wpctl set-volume @DEFAULT_AUDIO_SINK@ ''${2-${increments}}%-
    [[ $1 == "set" ]] && {
      volume=''${2-100}
      [[ $volume -gt 100 ]] && volume=100
      wpctl set-volume @DEFAULT_AUDIO_SINK@ ''${volume}%
    }
  '';
  sound-up = pkgs.writeShellScriptBin "sound-up" ''
    sound-change up ${increments}
  '';
  sound-set = pkgs.writeShellScriptBin "sound-set" ''
    sound-change set ''${1-100}
  '';
  sound-down = pkgs.writeShellScriptBin "sound-down" ''
    sound-change down ${increments}
  '';
  sound-toggle = pkgs.writeShellScriptBin "sound-toggle" ''
    sound-change mute
  '';
in
{
  home.packages = [
    sound-change
    sound-up
    sound-down
    sound-toggle
    sound-set
  ];
}
