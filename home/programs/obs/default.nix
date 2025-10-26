# OBS Studio configuration.

{ pkgsStable, ... }:

{
  programs.obs-studio = {
    enable = true; # Enable OBS Studio for streaming and recording

    # OBS Studio plugins for enhanced functionality
    plugins = with pkgsStable.obs-studio-plugins; [
      input-overlay # Display keyboard/mouse input on screen
      wlrobs # Wayland screen capture support
      obs-backgroundremoval # AI-powered background removal
      obs-pipewire-audio-capture # PipeWire audio capture support
    ];
  };
}
