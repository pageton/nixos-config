# Audio configuration (PipeWire).

{ config, lib, ... }:

{
  # Validation: Ensure PulseAudio and PipeWire don't conflict
  assertions = [
    {
      assertion = !(config.services.pulseaudio.enable && config.services.pipewire.enable);
      message = "PulseAudio and PipeWire cannot be enabled simultaneously";
    }
  ];

  security.rtkit.enable = true;

  services = {
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
