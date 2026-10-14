# OBS Studio configuration with essential plugins.
{ pkgs, ... }: {
  programs.obs-studio = {
    enable = true;

    plugins = with pkgs.obs-studio-plugins; [
      input-overlay # Display keyboard/mouse input
      wlrobs # Wayland screen capture
      obs-backgroundremoval # AI background removal
      obs-pipewire-audio-capture # PipeWire audio capture
      obs-vkcapture # Vulkan/OpenGL game capture
      obs-gstreamer # GStreamer integration for more sources
      obs-vaapi # VA-API hardware encoding (AMD/Intel)
      # obs-studio 32 marks obs_properties_add_button OBS_DEPRECATED; exeldro
      # plugins still call it and vendor -Werror via obs-plugintemplate.
      # Drop these overrides once upstream releases 32-compatible versions.
      (obs-move-transition.overrideAttrs (_: {
        env.NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-declarations";
      }))
      (obs-shaderfilter.overrideAttrs (prev: {
        env.NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-declarations";
        # GCC 16 propagates const through the strrchr() builtin, so assigning
        # its result on a const char* to char* is a hard -Werror failure.
        # `pos` is only used for pointer arithmetic, so const is correct.
        postPatch = (prev.postPatch or "") + ''
          substituteInPlace obs-shaderfilter.c \
            --replace-fail "char *pos = strrchr(file_name, '/');" \
                          "const char *pos = strrchr(file_name, '/');"
        '';
      }))
      obs-source-record # Record individual sources separately
      advanced-scene-switcher # Automate scene switching
    ];
  };
}
