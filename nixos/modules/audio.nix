# Audio configuration (PipeWire).
{
  config,
  lib,
  hostname,
  ...
}: {
  # Validation: Ensure PulseAudio and PipeWire don't conflict
  assertions = lib.mkIf (hostname != "server") [
    {
      assertion = !(config.services.pulseaudio.enable && config.services.pipewire.enable);
      message = "PulseAudio and PipeWire cannot be enabled simultaneously";
    }
  ];

  services = lib.mkIf (hostname != "server") {
    pulseaudio.enable = false;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}
