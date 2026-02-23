# Audio configuration (PipeWire).
{
  config,
  lib,
  ...
}: {
  # Validation: Ensure PulseAudio and PipeWire don't conflict
  config.assertions = [
    {
      assertion = !(config.services.pulseaudio.enable && config.services.pipewire.enable);
      message = "PulseAudio and PipeWire cannot be enabled simultaneously";
    }
  ];

  config.services = {
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